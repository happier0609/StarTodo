//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel
@MainActor
final class ReportViewModel: ObservableObject {
    
    // ✅ Coordinator 참조
    weak var coordinator: MainCoordinator?
    
    // ✅ MainViewModel 참조 (리팩토링 후 추가)
    weak var mainViewModel: MainViewModel?
    
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
    
    init(session: FocusSession, context: ModelContext) {
        self.modelContext = context
        
        print("리포트 초기화 - 휴식 기록 개수: \(session.breaks.count)")
        
        self.session = session
        self.breaks = session.breaks
        
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
        
        // 타임라인 구성
        buildTimeline()
    }
    
    // MARK: - 타임라인 빌드
    
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
    
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedSeconds }
    }
    
    var totalFocusedMinutes: Int {
        totalFocusedSeconds / 60
    }
    
    var totalBreakMinutes: Int {
        session.totalBreakSeconds / 60
    }
    
    var breakCount: Int {
        breaks.count
    }
    
    var totalFocusedTimeText: String {
        let hours = totalFocusedMinutes / 60
        let minutes = totalFocusedMinutes % 60
        return "\(hours)시간 \(minutes)분"
    }
    
    var totalCount: Int { todos.count }
    var completedCount: Int { completedTodos.count }
    
    // MARK: - 계획 시간 관련
    
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setSeconds / 60 }
        guard mins.allSatisfy({ $0 > 0 }) else { return nil }
        return mins.reduce(0, +)
    }
    
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
    
    func finalizeSession() async {
        session.endedAt = Date()
        
        print("📝 ReportViewModel: 세션 종료 처리 시작")
        print("  - 완료된 항목: \(completedTodos.count)개")
        print("  - 미완료 항목: \(incompletedTodos.count)개")
        
        do {
            try modelContext.save()
            print("✅ ReportViewModel: 세션 데이터 저장 성공")
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            print("✅ ReportViewModel: 변경사항 전파 대기 완료")
            
        } catch {
            print("❌ ReportViewModel: 세션 데이터 저장 실패 - \(error.localizedDescription)")
        }
        
        // ✅ 리팩토링 후: MainViewModel 갱신으로 변경
        await MainActor.run {
            mainViewModel?.fetchTodos()
            print("✅ ReportViewModel: MainViewModel 갱신 완료")
        }
    }
    
    // MARK: - 화면 닫기
    
    func dismissReport() {
        print("📊 ReportView 닫기")
        coordinator?.dismissFullScreen()
        coordinator?.popToRoot()
    }
}

// MARK: - Static Factory Method

extension ReportViewModel {
    
    /// `PersistentIdentifier` 기반으로 FocusSession을 불러와 ReportViewModel 생성
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
                
                // ✅ 이전 화면으로 (안전하게)
                coordinator?.pop()
                return nil
            }
            
            print("✅ FocusSession 로딩 성공")
            print("  휴식 기록: \(session.breaks.count)개")
            
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
