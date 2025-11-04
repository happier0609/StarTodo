//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel (SwiftData 버전)
@MainActor
final class ReportViewModel: ObservableObject {
    
    // ModelContext를 인스턴스 변수로 저장하여 일관성 보장
    private let modelContext: ModelContext
    private var session: FocusSession
    
    // 전체 할 일 목록
    @Published var todos: [ReportItem] = []
    
    // 타임라인용 통합 리스트 (할 일 + 휴식) - ReportRowType 사용
    @Published var timelineItems: [ReportRowType] = []
    
    // 완료/미완료 분리 리스트 (UI 편의용)
    @Published var completedTodos: [ReportItem] = []
    @Published var incompletedTodos: [ReportItem] = []
    
    // 휴식 기록
    @Published var breaks: [BreakSession] = []
    
    // MARK: - 초기화
    
    // ModelContext를 주입받아 저장
    init(session: FocusSession, context: ModelContext) {
        self.modelContext = context
        
        print("리포트 초기화 - 휴식 기록 개수: \(session.breaks.count)")
        
        self.session = session
        self.breaks = session.breaks
        
        // FocusItem을 ReportItem으로 변환하면서 완료 시간 추정
        var cumulativeTime: TimeInterval = 0
        let items = session.items.map { item -> ReportItem in
            // 완료된 아이템의 경우 누적 시간으로 performedDate 추정
            if item.isCompleted && item.elapsedSeconds > 0 {
                cumulativeTime += TimeInterval(item.elapsedSeconds)
                return ReportItem(
                    title: item.title,
                    setSeconds: item.setSeconds,
                    elapsedSeconds: item.elapsedSeconds,
                    isCompleted: item.isCompleted,
                    order: item.order,
                    performedDate: session.startedAt.addingTimeInterval(cumulativeTime)
                )
            } else {
                return ReportItem(
                    title: item.title,
                    setSeconds: item.setSeconds,
                    elapsedSeconds: item.elapsedSeconds,
                    isCompleted: item.isCompleted,
                    order: item.order,
                    performedDate: nil
                )
            }
        }
        
        self.todos = items
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
        
        // 타임라인 구성
        buildTimeline()
    }
    
    // MARK: - 타임라인 빌드 (ReportRowType 사용)
    private func buildTimeline() {
        var timeline: [ReportRowType] = []
        
        // 완료된 할 일들을 타임라인에 추가
        for todo in completedTodos {
            timeline.append(.completed(todo))
        }
        
        // 휴식 기록을 타임라인에 추가
        for breakSession in breaks {
            timeline.append(.breakSession(breakSession))
        }
        
        // 시간순 정렬
        timeline.sort { item1, item2 in
            let date1: Date
            let date2: Date
            
            switch item1 {
            case .completed(let item):
                date1 = item.performedDate ?? Date.distantPast
            case .incompleted(let item):
                date1 = item.performedDate ?? Date.distantPast
            case .breakSession(let breakItem):
                date1 = breakItem.end
            }
            
            switch item2 {
            case .completed(let item):
                date2 = item.performedDate ?? Date.distantPast
            case .incompleted(let item):
                date2 = item.performedDate ?? Date.distantPast
            case .breakSession(let breakItem):
                date2 = breakItem.end
            }
            
            return date1 < date2
        }
        
        self.timelineItems = timeline
    }
    
    // MARK: - 데이터 로딩
    
    /// 완료 여부와 상관없이, "수행된(performedDate != nil)" 항목만 리포트 대상으로 채택
    func fetchTodos(from allTodos: [Todo]) {
        // 1. 수행된 항목만
        let performed = allTodos.filter { $0.performedDate != nil }
        
        // 2. ReportItem 변환 시 performedDate도 함께 보관
        let reportItems: [ReportItem] = performed.map { todo in
            ReportItem(
                title: todo.title,
                setSeconds: todo.setTime,
                elapsedSeconds: todo.elapsedTime,
                isCompleted: todo.isCompleted,
                order: todo.order,
                performedDate: todo.performedDate
            )
        }
        
        // 3. 정렬: 완료된 항목은 performedDate 기준 정렬, 미완료는 뒤로
        self.todos = reportItems.sorted {
            switch ($0.performedDate, $1.performedDate) {
            case let (.some(date1), .some(date2)):
                return date1 < date2
            case (.some, .none):
                return true  // performedDate가 있는 게 먼저
            case (.none, .some):
                return false // performedDate가 없는 게 나중
            case (.none, .none):
                return false
            }
        }
        
        // 4. 완료/미완료 분리
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
    }
    
    // MARK: - 총합/통계
    
    /// 총 집중 시간(초)
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedSeconds }
    }
    
    /// 총 집중 시간(분)
    var totalFocusedMinutes: Int {
        totalFocusedSeconds / 60
    }
    
    /// 총 휴식 시간(분)
    var totalBreakMinutes: Int {
        session.totalBreakSeconds / 60
    }
    
    /// 휴식 횟수
    var breakCount: Int {
        breaks.count
    }
    
    /// 총 집중 시간 텍스트: "X시간 Y분"
    var totalFocusedTimeText: String {
        let hours = totalFocusedMinutes / 60
        let minutes = totalFocusedMinutes % 60
        return "\(hours)시간 \(minutes)분"
    }
    
    /// 전체 할 일 개수
    var totalCount: Int { todos.count }
    
    /// 완료한 할 일 개수
    var completedCount: Int { completedTodos.count }
    
    // MARK: - 계획 시간 관련
    
    /// 전체 수행 항목의 계획 시간(setTime, 분) 합
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setSeconds / 60 }
        guard mins.allSatisfy({ $0 > 0 }) else { return nil }
        return mins.reduce(0, +)
    }
    
    /// 총 실제 시간 vs 총 계획 시간 비교 텍스트
    var timeComparisonMessage: String? {
        guard let planned = totalPlannedMinutes else { return nil }
        
        let actual = totalFocusedMinutes
        if actual > planned {
            return "\(actual - planned)분 더 집중"
        } else if actual < planned {
            return "\(planned - actual)분 일찍 완료"
        } else {
            return nil
        }
    }
    
    // MARK: - 개별 항목 비교
    
    /// 개별 ReportItem의 계획/실제 시간 비교 텍스트
    func timeDescription(for item: ReportItem) -> String? {
        guard item.isCompleted else { return nil }
        
        let plannedMin = item.setSeconds / 60
        let actualMin = item.elapsedSeconds / 60
        
        guard plannedMin > 0 else { return nil }
        
        if actualMin > plannedMin {
            return "\(actualMin - plannedMin)분 더 집중"
        } else if actualMin < plannedMin {
            return "\(plannedMin - actualMin)분 일찍 완료"
        } else {
            return nil
        }
    }
    
    /// 휴식 시간 설명 텍스트
    func breakDescription(for breakSession: BreakSession) -> String {
        let duration = Int(breakSession.duration)
        let minutes = duration / 60
        let seconds = duration % 60
        
        if minutes > 0 {
            return breakSession.isOverdue ? "\(minutes)분 초과" : "\(minutes)분 충전"
        } else {
            return breakSession.isOverdue ? "\(seconds)초 초과" : "\(seconds)초 충전"
        }
    }
    
    // MARK: - 세션 종료 처리
    func finalizeSession() {
        session.endedAt = Date()
        // SwiftData는 변경사항 자동 저장됨
        
        // ✅ 완료된 Todo들의 상태를 다시 한 번 확인 및 저장
        // (이미 FocusModeViewModel에서 저장했지만, 안전장치로 추가)
        print("📝 ReportView에서 세션 종료 처리")
        print("  - 완료된 항목: \(completedTodos.count)개")
        print("  - 미완료 항목: \(incompletedTodos.count)개")
    }
}

extension ReportViewModel {
    
    /// `PersistentIdentifier` 기반으로 SwiftData에서 FocusSession을 불러와 ViewModel을 초기화
    convenience init(sessionID: PersistentIdentifier) {
        
        let context = defaultContext
        
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.persistentModelID == sessionID },
            sortBy: []
        )
        
        guard let session = try? context.fetch(descriptor).first else {
            fatalError("⚠️ 해당 ID의 FocusSession을 찾을 수 없습니다.")
        }
        
        print("🟢 ReportViewModel 초기화 - sessionID: \(session.persistentModelID)")
        print("🟢 휴식 기록 개수: \(session.breaks.count)")
        
        self.init(session: session)
    }
}
