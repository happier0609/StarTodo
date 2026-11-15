//
//  FocusModeViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class FocusModeViewModel: ObservableObject {
    
    @Published var shouldNavigateToReport: Bool = false
    @Published var showEndConfirmAlert: Bool = false
    
    // MARK: - 세션 저장 및 관계 연결용
    @Published var focusSession: FocusSession? = nil
    @Published var savedSession: FocusSession? = nil
    var modelContext: ModelContext
    private var store: SessionStore
    
    // MARK: - 할 일 관련 상태 (Todo 모델 직접 사용)
    @Published var todos: [Todo] = []                // SwiftData Todo 모델 직접 사용
    @Published var todoTimeSettings: [UUID: Int] = [:] // 각 Todo의 설정 시간 (분)
    @Published var todoElapsed: [UUID: Int] = [:]    // 각 Todo의 경과 시간 (초)
    @Published var currentIndex: Int = 0
    @Published var isRunning: Bool = false
    private var todoTimer: Timer?

    // 시각 기반 측정: 현재 구간을 시작한 시각과, 그 시점까지 누적된 경과 시간
    // → 화면이 잠기거나 앱이 백그라운드에 있어도 실제 흐른 시간으로 계산됨
    private var segmentTodoID: UUID?
    private var segmentStartDate: Date?
    private var segmentBaseElapsed: Int = 0
    private let maxElapsedSeconds = 120 * 60

    // NEW: 120분 도달 알림용
    @Published var show120MinAlert: Bool = false // NEW
    
    // 현재 진행 중인 할 일
    var currentTodo: Todo? {
        guard todos.indices.contains(currentIndex) else { return nil }
        return todos[currentIndex]
    }
    
    // 현재 할 일의 설정 시간 (분)
    var currentSetMinutes: Int {
        guard let todo = currentTodo else { return 0 }
        return todoTimeSettings[todo.id] ?? 0
    }
    
    // 현재 할 일의 경과 시간 (초)
    var currentElapsedSeconds: Int {
        guard let todo = currentTodo else { return 0 }
        return todoElapsed[todo.id] ?? 0
    }
    
    // 현재 할 일의 완료 여부 (bool)
    var isCurrentTodoCompleted: Bool {
        guard currentIndex < todos.count else { return false }
        return todos[currentIndex].isCompleted
    }
    
    // MARK: - 휴식 관련 상태
    @Published var isBreakActive: Bool = false
    @Published var showBreakSheet: Bool = false
    @Published var breakPickedMinutes: Int = 10
    @Published private(set) var breakTotalSeconds: Int = 0      // 지금까지 끝난 휴식의 누적 시간(초)
    @Published private(set) var breakPlannedSeconds: Int = 0    // 진행 중인 휴식의 계획 시간(초)
    @Published private(set) var breakElapsed: Int = 0
    @Published var showBreakEndOverlay: Bool = false
    @Published var breakSessions: [BreakSession] = []
    
    private var breakTimer: Timer?
    private var breakStartDate: Date?
    
    // MARK: - 헤더 시간 정보
    private enum TimeHeaderStatus {
        case plannedRemaining(Int)  // 설정 > 진행 → 남은 시간(초)
        case plannedOvertime(Int)   // 설정 < 진행 → 추가 시간(초)
        case noPlan                 // 설정 없음
        case breakRemaining(Int)    // 휴식 중 → 남은 시간(초)
    }
    
    // MARK: - 초기화
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.store = SwiftDataSessionStore(context: modelContext)
    }
    
    convenience init(todoIDs: [UUID], context: ModelContext) {
        let pairs = todoIDs.enumerated().map { (offset, id) in (id, 25) }
        self.init(todoIDPairs: pairs, context: context, store: SwiftDataSessionStore(context: context))
    }
    
    // MARK: - 메인 초기화
    init(todoIDPairs: [(UUID, Int)], context: ModelContext, store: SessionStore) {
        self.modelContext = context
        self.store = store
        
        print("FocusModeViewModel 초기화 시작")
        print("전달받은 데이터: \(todoIDPairs)")
        print("----------------------------------")
        
        loadTodos(todoPairs: todoIDPairs, context: context)
    }
    
    // MARK: - Load Todos (기존 Todo 모델 사용)
    private func loadTodos(todoPairs: [(UUID, Int)], context: ModelContext) {
        var loadedTodos: [Todo] = []
        
        print("Todo 로딩 시작...")
        
        for (_, (id, setTimeMinutes)) in todoPairs.enumerated() {
            do {
                let descriptor = FetchDescriptor<Todo>(
                    predicate: #Predicate { todo in todo.id == id }
                )
                
                if let todo = try context.fetch(descriptor).first {
                    loadedTodos.append(todo)
                    
                    // 시간 설정 저장
                    if setTimeMinutes > 0 {
                        todoTimeSettings[todo.id] = setTimeMinutes
                    } else {
                        // '없음' 설정인 경우 기본값 사용 안함
                        todoTimeSettings[todo.id] = 0
                    }
                    
                    // 경과 시간 초기화
                    todoElapsed[todo.id] = 0
                    
                    print("로드 성공: \(todo.title) - \(setTimeMinutes > 0 ? "\(setTimeMinutes)분" : "시간 없음")")
                } else {
                    print("Todo를 찾을 수 없음: \(id)")
                }
            } catch {
                print("Todo 로드 실패: \(id), 에러: \(error.localizedDescription)")
            }
        }
        
        self.todos = loadedTodos
        self.currentIndex = 0
        
        print("최종 로드된 Todo 개수: \(loadedTodos.count)")
        
        if !todos.isEmpty {
            print("타이머 시작")
            startTodoTimer()
        } else {
            print("로드된 할 일이 없어서 타이머를 시작하지 않습니다.")
        }
        print("----------------------------------")
    }
    
    func reloadTodos(todoPairs: [(UUID, Int)]) {
        loadTodos(todoPairs: todoPairs, context: modelContext)
    }
    
    // MARK: - 휴식 로직
    func startBreak() {
        print("휴식 시작: \(breakPickedMinutes)분")
        // 휴식 전까지 흐른 집중 시간을 먼저 반영
        flushCurrentElapsed()
        todoTimer?.invalidate()
        todoTimer = nil
        isRunning = false

        isBreakActive = true
        let start = Date()
        breakStartDate = start
        breakElapsed = 0
        breakPlannedSeconds = breakPickedMinutes * 60
        startBreakTimer()

        // 앱 밖에 있어도 휴식 종료를 알 수 있도록 로컬 알림 예약
        BreakNotificationScheduler.schedule(after: TimeInterval(breakPlannedSeconds))
        print("----------------------------------")
    }
    
    private func startBreakTimer() {
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onBreakTimerTick()
            }
        }
    }
    
    private func onBreakTimerTick() {
        guard isBreakActive, let start = breakStartDate else { return }

        // 틱 횟수가 아니라 실제 흐른 시간으로 계산
        breakElapsed = max(0, Int(Date().timeIntervalSince(start)))

        if breakElapsed >= breakPlannedSeconds && !showBreakEndOverlay {
            print("휴식 시간 종료 알림 표시")
            showBreakEndOverlay = true
        }
    }

    func endBreak() {
        print("휴식 종료")
        breakTimer?.invalidate()
        breakTimer = nil
        showBreakEndOverlay = false
        BreakNotificationScheduler.cancel()

        if let start = breakStartDate {
            let end = Date()
            let duration = end.timeIntervalSince(start)
            let isOver = duration > Double(breakPlannedSeconds)
            
            let record = BreakSession(start: start, end: end, isOverdue: isOver)
            record.session = focusSession
            
            modelContext.insert(record)
            breakSessions.append(record)
            breakTotalSeconds += Int(duration)
            
            print("휴식 기록 저장 완료: \(Int(duration))초")
        }
        print("----------------------------------")
        breakStartDate = nil
        breakPlannedSeconds = 0
        isBreakActive = false
    }
    
    func endBreakAndResume() {
        print("휴식 종료 후 할 일 재시작")
        endBreak()
        resumeCurrentTodo()
        print("----------------------------------")
    }
    
    // MARK: - 정렬된 할 일 목록
    /// 목록 탭 표시 순서: 처음 고른 순서를 유지하고, 완료한 일만 아래로 내림
    /// (이전에는 '목표 시간이 다 찬 일'을 위로 올려서, 시간이 지나거나 목표 시간이 '없음'이면
    ///  완료하지 않았는데도 순서가 바뀌었음)
    var sortedTodosForListView: [Todo] {
        todos.filter { !$0.isCompleted } + todos.filter { $0.isCompleted }
    }
    
    /// 화면 정렬 순서와 무관하게 id로 할 일을 선택
    func selectTodo(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        // 이미 완료한 일은 다시 선택하지 않음 (선택되면 완료한 일에 시간이 계속 쌓임)
        guard !todos[index].isCompleted else { return }
        selectTodo(at: index)
    }

    /// 화면 정렬 순서와 무관하게 id로 할 일을 완료 처리
    func markTodoAsCompleted(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        markTodoAsCompleted(at: index)
    }

    func selectTodo(at index: Int) {
        guard todos.indices.contains(index) else { return }
        print("할 일 선택: \(index) - \(todos[index].title)")
        // 이전 할 일에 지금까지 흐른 시간을 반영한 뒤 전환
        flushCurrentElapsed()
        currentIndex = index
        
        if !isBreakActive {
            startTodoTimer()
        }
        print("----------------------------------")
    }
    
    // MARK: - Timer Logic
    private func startTodoTimer() {
        guard !isBreakActive else {
            print("휴식 중이므로 할 일 타이머를 시작하지 않습니다.")
            return
        }
        
        startFocusSessionIfNeeded()
        
        todoTimer?.invalidate()
        isRunning = true

        // 현재 할 일의 측정 구간 시작
        if let todo = currentTodo {
            segmentTodoID = todo.id
            segmentBaseElapsed = todoElapsed[todo.id, default: 0]
            segmentStartDate = Date()
        }

        print("할 일 타이머 시작: \(currentTodo?.title ?? "알 수 없음")")

        // 타이머는 화면 갱신용. 시간 값은 segmentStartDate 기준으로 계산
        todoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onTodoTimerTick()
            }
        }
    }

    func stopTimer() {
        print("할 일 타이머 중지")
        flushCurrentElapsed()
        todoTimer?.invalidate()
        todoTimer = nil
        isRunning = false
        print("----------------------------------")
    }

    /// 진행 중인 구간의 실제 경과 시간을 계산 (초)
    private func measuredElapsed() -> Int? {
        guard let start = segmentStartDate else { return nil }
        let seconds = segmentBaseElapsed + max(0, Int(Date().timeIntervalSince(start)))
        return min(seconds, maxElapsedSeconds)
    }

    /// 진행 중인 구간의 경과 시간을 todoElapsed에 반영하고 구간을 닫음
    private func flushCurrentElapsed() {
        if let id = segmentTodoID, let elapsed = measuredElapsed() {
            todoElapsed[id] = elapsed
        }
        segmentTodoID = nil
        segmentStartDate = nil
    }

    /// 앱이 다시 활성화되었을 때 화면 값을 즉시 갱신
    /// (백그라운드에 있는 동안 멈춰 있던 타이머 대신 실제 흐른 시간을 바로 보여줌)
    func refreshAfterForeground() {
        if isBreakActive {
            onBreakTimerTick()
        } else {
            onTodoTimerTick()
        }
    }
    
    func resumeCurrentTodo() {
        guard todos.indices.contains(currentIndex) else { return }
        guard !isCurrentTodoCompleted else { return }
        guard todoTimer == nil else { return }
        
        print("할 일 재시작: \(todos[currentIndex].title)")
        startTodoTimer()
        print("----------------------------------")
    }
    
    // CHANGED: 120분 자동 완료 로직으로 변경
    private func onTodoTimerTick() {
        guard let todo = currentTodo, todo.id == segmentTodoID else { return }
        guard !isBreakActive else { return } // NEW: 휴식 중에는 증가하지 않음
        guard let currentElapsed = measuredElapsed() else { return }

        todoElapsed[todo.id] = currentElapsed

        // CHANGED: 120분(7200초) 도달 시 자동 완료
        if currentElapsed >= maxElapsedSeconds { // 7200초
            print("⏰ 120분 진행 완료: \(todo.title)")
            print("  경과 시간: \(currentElapsed)초")
            
            // NEW: 알림 표시
            show120MinAlert = true
            
            // NEW: 자동 완료 처리
            completeCurrentTodo()
        }
    }
    
    func startFocusSessionIfNeeded() {
        if focusSession == nil {
            let session = FocusSession(startedAt: Date(), endedAt: Date(), totalBreakSeconds: 0)
            modelContext.insert(session)
            focusSession = session
            print("집중 세션 생성")
        }
        print("----------------------------------")
    }
    
    // MARK: - Complete & Move to Next
    func completeCurrentTodo() {
        markTodoAsCompleted(at: currentIndex)
    }

    func markTodoAsCompleted(at index: Int) {
        guard todos.indices.contains(index) else { return }
        let todo = todos[index]
        
        // 진행 중인 할 일이면 완료 직전까지 흐른 시간을 반영
        if index == currentIndex {
            flushCurrentElapsed()
        }

        print("🎯 FocusMode 완료 처리 시작: \(todo.title)")
        print("  이전 상태:")
        print("    - isCompleted: \(todo.isCompleted)")
        print("    - performedDate: \(todo.performedDate?.description ?? "nil")")
        
        // ✅ 경과 시간 가져오기
        let elapsedSeconds = todoElapsed[todo.id, default: 0]
        
        // ✅ 통일된 Extension 메서드 사용
        do {
            try todo.markAsCompleted(context: modelContext, elapsedSeconds: elapsedSeconds)
            
            print("  완료 처리 후:")
            print("    - isCompleted: \(todo.isCompleted)")
            print("    - performedDate: \(todo.performedDate?.description ?? "nil")")
            
            // ✅ context가 제대로 저장되었는지 확인
            print("  ModelContext 저장 확인:")
            print("    - hasChanges: \(modelContext.hasChanges)")
            
            // ✅ 자식이 있는 경우: 모든 자식도 완료 처리
            if !todo.children.isEmpty {
                print("  자식 완료 처리:")
                for child in todo.children where !child.isCompleted {
                    let childElapsed = todoElapsed[child.id, default: 0]
                    try child.markAsCompleted(context: modelContext, elapsedSeconds: childElapsed)
                    print("    - \(child.title): 완료 처리됨")
                }
            }
            
            // ✅ 자식인 경우: 모든 형제가 완료되었는지 확인
            if let parent = todo.parent {
                let allSiblingsCompleted = parent.children.allSatisfy { $0.isCompleted }
                print("  부모 확인: \(parent.title)")
                print("    - 모든 형제 완료 여부: \(allSiblingsCompleted)")
                
                if allSiblingsCompleted && !parent.isCompleted {
                    let parentElapsed = todoElapsed[parent.id, default: 0]
                    try parent.markAsCompleted(context: modelContext, elapsedSeconds: parentElapsed)
                    print("    - 부모도 완료 처리됨")
                }
            }
            
        } catch {
            print("❌ Todo 완료 처리 실패: \(error.localizedDescription)")
        }
        
        // ✅ 다음 Todo로 이동
        if index == currentIndex {
            stopTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.moveToNextTodo()
            }
        }
    }

    private func moveToNextTodo() {
        // todos 중에서 아직 완료되지 않은 첫 번째 항목을 찾아 이동
        let next = todos.enumerated().first { (_, todo) in
            !todo.isCompleted
        }
        
        if let (index, nextTodo) = next {
            currentIndex = index
            print("다음 할 일로 이동: \(nextTodo.title)")
            startTodoTimer()
        } else {
            print("모든 할 일 완료!")
            isRunning = false
            endFocusSession()
        }
        print("----------------------------------")
    }

    // MARK: - 세션 종료
    func endFocusSession() {
        print("집중 세션 종료")
        stopTimer()
        // 휴식 중에 종료한 경우에도 그 휴식을 기록하고 예약된 알림을 취소
        if isBreakActive {
            endBreak()
        }
        breakTimer?.invalidate()
        breakTimer = nil
        BreakNotificationScheduler.cancel()
        isRunning = false
        isBreakActive = false
        
        // 휴식 기록 디버깅
        print("저장할 휴식 기록 개수: \(breakSessions.count)")
        for (index, breakSession) in breakSessions.enumerated() {
            print("휴식 \(index): \(breakSession.start) ~ \(breakSession.end)")
        }
        
        if let session = focusSession {
            session.endedAt = Date()
            session.totalBreakSeconds = breakTotalSeconds
            session.breaks = breakSessions
            print("FocusSession에 연결된 휴식 개수: \(session.breaks.count)")
            
            // 디버깅: 저장 전 상태 확인
            print("저장 전 데이터:")
            print("- todoTimeSettings: \(todoTimeSettings)")
            print("- todoElapsed: \(todoElapsed)")
            
            // ✅ FocusItem 생성 (리포트용)
            session.items = todos.enumerated().map { (index, todo) in
                let setSeconds = todoTimeSettings[todo.id, default: 0] * 60
                let elapsedSeconds = todoElapsed[todo.id, default: 0]
                
                print("FocusItem: \(todo.title) - 경과:\(elapsedSeconds)초, 완료:\(todo.isCompleted)")
                
                return FocusItem(
                    title: todo.title,
                    setSeconds: setSeconds,
                    elapsedSeconds: elapsedSeconds,
                    isCompleted: todo.isCompleted,
                    order: index
                )
            }
            
            session.breaks = breakSessions
            
            // ✅ 모든 Todo의 elapsedTime 최종 업데이트
            print("\n📝 Todo elapsedTime 최종 업데이트:")
            for todo in todos {
                let elapsedSeconds = todoElapsed[todo.id, default: 0]
                todo.elapsedTime = elapsedSeconds
                print("  - \(todo.title): \(elapsedSeconds)초, 완료: \(todo.isCompleted)")
            }
            
            // ✅ 한 번에 모두 저장
            do {
                try modelContext.save()
                print("✅ 세션 및 Todo 상태 최종 저장 완료")
                print("  - FocusSession items: \(session.items.count)개")
                print("  - Breaks: \(session.breaks.count)개")
                print("  - 업데이트된 Todo: \(todos.count)개")
            } catch {
                print("❌ 세션 저장 실패: \(error.localizedDescription)")
            }
            
            savedSession = session
            
            // ✅ Coordinator: FocusModeView 닫고 ReportView 띄우기
            MainCoordinator.shared.dismissFullScreen()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let id = session.persistentModelID
                MainCoordinator.shared.presentFullScreen(.report(sessionID: id))
            }
        }
        print("----------------------------------")
    }
    
    func replaceStoreWithContext() {
        let store = SwiftDataSessionStore(context: modelContext)
        self.store = store
    }
    
    // MARK: - 남은/추가 시간 계산
    var headerLabelText: String {
        switch timeHeaderStatus {
        case .plannedRemaining: return "남은 시간"
        case .plannedOvertime:  return "추가 시간"
        case .noPlan:           return "시간을 설정하지 않았습니다"
        case .breakRemaining:   return "남은 시간"
        }
    }

    var headerTimeText: String? {
        switch timeHeaderStatus {
        case .plannedRemaining(let sec),
             .plannedOvertime(let sec),
             .breakRemaining(let sec):
            return formatTime(seconds: sec)
        case .noPlan:
            return nil
        }
    }
    
    // MARK: - 텍스트 표시용
    var headerStatusText: String {
        if isBreakActive {
            let m = max(0, breakElapsed / 60)
            return "\(m)분째 휴식 중..."
        } else {
            return "\(elapsedTotalMinutes)분 째 탐사 중..."
        }
    }
    
    var displaySetMinutes: Int {
        if isBreakActive { return breakPickedMinutes }
        return currentSetMinutes
    }
    
    var displayElapsedSeconds: Int {
        if isBreakActive { return breakElapsed }
        return currentElapsedSeconds
    }
    
    private var timeHeaderStatus: TimeHeaderStatus {
        // 1) 휴식 중
        if isBreakActive {
            let remaining = max(breakPlannedSeconds - breakElapsed, 0)
            return .breakRemaining(remaining)
        }

        // 2) 설정 시간이 '없음'인 경우
        let plannedSeconds = currentSetMinutes * 60
        if plannedSeconds <= 0 {
            return .noPlan
        }

        // 3) 설정 시간 있음 → 남은/추가 시간 계산
        let elapsed = currentElapsedSeconds
        if elapsed < plannedSeconds {
            return .plannedRemaining(plannedSeconds - elapsed)
        } else if elapsed > plannedSeconds {
            return .plannedOvertime(elapsed - plannedSeconds)
        } else {
            return .plannedRemaining(0)
        }
    }
    
    var expectedEndTimeString: String {
        // 완료하지 않은 모든 할 일의 남은 계획 시간을 합산
        // (이전: 현재 할 일부터 뒤쪽만 더해서, 목록에서 순서를 건너뛰어 고르면 앞쪽 미완료 일이 빠지고
        //  이미 완료한 일의 남은 시간은 더해지는 문제가 있었음)
        let taskRemainingSeconds = todos.filter { !$0.isCompleted }.reduce(0) { result, todo in
            let setSeconds = todoTimeSettings[todo.id, default: 0] * 60
            let elapsed = todoElapsed[todo.id, default: 0]
            return result + max(0, setSeconds - elapsed)
        }
        
        // 이미 끝난 휴식은 지나간 시간이므로 제외하고, 진행 중인 휴식의 남은 시간만 더함
        let breakRemainingSeconds = isBreakActive ? max(breakPlannedSeconds - breakElapsed, 0) : 0
        let totalRemaining = taskRemainingSeconds + breakRemainingSeconds
        
        let endDate = Date().addingTimeInterval(TimeInterval(totalRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: endDate)
    }
    
    var elapsedTotalMinutes: Int {
        let totalSeconds = todoElapsed.values.reduce(0, +)
        return totalSeconds / 60
    }
    
    deinit {
        print("FocusModeViewModel deinit")
        todoTimer?.invalidate()
        breakTimer?.invalidate()
    }
    
    private func formatTime(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
