//
//  ReportViewModel.swift
//  StarTodo
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel
@MainActor
final class ReportViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    /// Coordinator 참조 (화면 전환용)
    weak var coordinator: MainCoordinator?
    
    /// MainViewModel 참조 (데이터 갱신용)
    weak var mainViewModel: MainViewModel?
    
    // MARK: - Properties
    
    /// ModelContext를 인스턴스 변수로 저장하여 일관성 보장
    private let modelContext: ModelContext
    
    /// 원본 FocusSession 참조
    private var session: FocusSession
    
    // MARK: - Published Properties
    
    /// 전체 할 일 목록
    @Published var todos: [ReportItem] = []
    
    /// 타임라인용 통합 리스트 (할 일 + 휴식)
    @Published var timelineItems: [ReportRowType] = []
    
    /// 완료된 할 일 목록
    @Published var completedTodos: [ReportItem] = []
    
    /// 미완료된 할 일 목록
    @Published var incompletedTodos: [ReportItem] = []
    
    /// 휴식 기록
    @Published var breaks: [BreakSession] = []
    
    // MARK: - 초기화
    
    init(session: FocusSession, context: ModelContext) {
        self.modelContext = context
        self.session = session
        self.breaks = session.breaks
        
        print("📊 ReportViewModel 초기화")
        print("  - 휴식 기록 개수: \(session.breaks.count)")
        print("  - FocusItem 개수: \(session.items.count)")
        
        // FocusItem을 ReportItem으로 변환하면서 완료 시간 추정
        var cumulativeTime: TimeInterval = 0
        let items = session.items.map { item -> ReportItem in
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
        
        print("  - 완료된 항목: \(completedTodos.count)개")
        print("  - 미완료 항목: \(incompletedTodos.count)개")
        
        // 타임라인 구성
        buildTimeline()
    }
    
    // MARK: - 타임라인 빌드
    
    /// 완료된 할 일과 휴식을 시간순으로 정렬하여 타임라인 생성
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
        
        print("  - 타임라인 항목: \(timeline.count)개")
    }
    
    // MARK: - 데이터 로딩 (구버전 호환용)
    
    /// Todo 모델로부터 데이터를 가져오는 메서드 (현재는 사용하지 않음)
    func fetchTodos(from allTodos: [Todo]) {
        let performed = allTodos.filter { $0.performedDate != nil }
        
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
        
        self.todos = reportItems.sorted {
            switch ($0.performedDate, $1.performedDate) {
            case let (.some(date1), .some(date2)):
                return date1 < date2
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return false
            }
        }
        
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
    }
    
    // MARK: - 총합/통계
    
    /// 총 집중 시간 (초 단위)
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedSeconds }
    }
    
    /// 총 집중 시간 (분 단위)
    var totalFocusedMinutes: Int {
        totalFocusedSeconds / 60
    }
    
    /// 총 휴식 시간 (분 단위)
    var totalBreakMinutes: Int {
        session.totalBreakSeconds / 60
    }
    
    /// 휴식 횟수
    var breakCount: Int {
        breaks.count
    }
    
    /// 총 집중 시간 텍스트 (예: "1시간 35분")
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
    
    /// 총 계획 시간 (분 단위) - 모든 할 일에 계획 시간이 있는 경우에만 반환
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setSeconds / 60 }
        guard mins.allSatisfy({ $0 > 0 }) else { return nil }
        return mins.reduce(0, +)
    }
    
    /// 계획 대비 실제 시간 비교 메시지
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
    
    /// 개별 할 일의 시간 설명 (예: "5분 더 집중", "10분 일찍 완료")
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
    
    /// 휴식 시간 설명 (예: "10분 충전", "5분 초과")
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
    
    /// 세션을 종료하고 데이터를 저장
    func finalizeSession() async {
        // 종료 시각은 집중모드가 끝날 때(FocusModeViewModel.endFocusSession) 이미 기록됨
        // 여기서 다시 덮어쓰면 결과판을 보고 있던 시간까지 세션에 포함되므로 변경하지 않음

        print("📝 ReportViewModel: 세션 종료 처리 시작")
        print("  - 완료된 항목: \(completedTodos.count)개")
        print("  - 미완료 항목: \(incompletedTodos.count)개")
        
        do {
            try modelContext.save()
            print("✅ ReportViewModel: 세션 데이터 저장 성공")
            
            // 변경사항 전파를 위한 짧은 대기
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            print("✅ ReportViewModel: 변경사항 전파 대기 완료")
            
        } catch {
            print("❌ ReportViewModel: 세션 데이터 저장 실패 - \(error.localizedDescription)")
        }
        
        // MainViewModel 갱신
        await MainActor.run {
            mainViewModel?.fetchTodos()
            print("✅ ReportViewModel: MainViewModel 갱신 완료")
        }
    }
    
    // MARK: - 화면 닫기
    
    /// 리포트 화면을 닫고 메인 화면으로 돌아감
    func dismissReport() {
        print("📊 ReportView 닫기")
        coordinator?.dismissFullScreen()
        coordinator?.popToRoot()
    }
}

// MARK: - Static Factory Method

extension ReportViewModel {
    
    /// PersistentIdentifier 기반으로 FocusSession을 불러와 ReportViewModel 생성
    /// - Parameters:
    ///   - sessionID: 불러올 FocusSession의 PersistentIdentifier
    ///   - context: ModelContext
    ///   - coordinator: MainCoordinator (옵션)
    ///   - mainViewModel: MainViewModel (옵션)
    /// - Returns: 생성에 실패한 경우 nil 반환
    @MainActor
    static func load(
        sessionID: PersistentIdentifier,
        context: ModelContext,
        coordinator: MainCoordinator?,
        mainViewModel: MainViewModel?
    ) -> ReportViewModel? {
        
        print("🔍 FocusSession 로딩 시작")
        print("  Session ID: \(sessionID)")
        
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.persistentModelID == sessionID }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            print("  조회 결과: \(sessions.count)개")
            
            guard let session = sessions.first else {
                print("⚠️ FocusSession을 찾을 수 없습니다.")
                
                // 전체 세션 확인 (디버깅)
                if let allSessions = try? context.fetch(FetchDescriptor<FocusSession>()) {
                    print("  전체 세션 수: \(allSessions.count)")
                    allSessions.forEach { s in
                        print("    - \(s.persistentModelID)")
                    }
                }
                
                // 이전 화면으로 (안전하게)
                coordinator?.pop()
                return nil
            }
            
            print("✅ FocusSession 로딩 성공")
            print("  - 아이템 수: \(session.items.count)")
            print("  - 휴식 기록: \(session.breaks.count)개")
            
            // ViewModel 생성
            let viewModel = ReportViewModel(session: session, context: context)
            viewModel.coordinator = coordinator
            viewModel.mainViewModel = mainViewModel
            
            return viewModel
            
        } catch {
            print("❌ FocusSession 조회 실패: \(error)")
            coordinator?.pop()
            return nil
        }
    }
}
