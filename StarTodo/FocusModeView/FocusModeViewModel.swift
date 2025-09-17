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
    
    @Published var shouldNavigateToReport: Bool = false   // ReportView로 이동 여부
    @Published var showEndConfirmAlert: Bool = false      // 세션 종료 확인 알림 표시
    
    // MARK: - 세션 저장 및 관계 연결용
    @Published var focusSession: FocusSession? = nil                      // 현재 포커스 세션 (휴식 기록과 연결됨)
    @Published var savedSession: FocusSession? = nil
    private let modelContext: ModelContext               // SwiftData 저장 컨텍스트
    private var store: SessionStore                      // 세션 저장소 (임시/SwiftData/디버그용 등)
    
    // MARK: - 할 일 관련 상태
    @Published var todos: [DummyTodo] = []               // 할 일 리스트
    @Published var currentIndex: Int = 0                 // 현재 인덱스
    @Published var isRunning: Bool = false               // 타이머 실행 중 여부
    private var todoTimer: Timer?                        // 할 일 타이머
    
    // 현재 진행 중인 할 일 (인덱스 유효성 검사 포함)
    var currentTodo: DummyTodo? {
        guard todos.indices.contains(currentIndex) else { return nil }
        return todos[currentIndex]
    }
    
    // MARK: - 휴식 관련 상태
    @Published var isBreakActive: Bool = false            // 현재 휴식 중 여부
    @Published var showBreakSheet: Bool = false           // 휴식 시간 선택 시트 노출 여부
    @Published var breakPickedMinutes: Int = 10           // 선택한 휴식 시간 (분 단위, 5~30)
    @Published private(set) var breakTotalSeconds: Int = 0// 총 휴식 시간 (초)
    @Published private(set) var breakElapsed: Int = 0     // 휴식 경과 시간 (초)
    @Published var showBreakEndOverlay: Bool = false      // 휴식 종료 오버레이 표시 여부
    @Published var breakSessions: [BreakSession] = []     // 휴식 기록 (SwiftData 모델)
    
    private var breakTimer: Timer?                        // 휴식용 타이머
    private var breakStartDate: Date?                     // 휴식 시작 시각
    
    // MARK: - 초기화
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.store = SwiftDataSessionStore(context: modelContext) // 또는 디버그용 store
    }
    
    // 커스텀 생성자
    convenience init(todoIDs: [UUID], context: ModelContext) {
        let pairs = todoIDs.enumerated().map { ($0.element, $0.offset) }
        self.init(todoIDPairs: pairs, context: context, store: SwiftDataSessionStore(context: context))
    }
    
    // MARK: - 휴식 타이머 로직
    // 휴식 시작 시 현재 시간을 저장하고, 타이머 시작
    func startBreak() {
        isBreakActive = true
        breakStartDate = Date()
        breakElapsed = 0
        startBreakTimer()
    }
    
    // 1초마다 breakElapsed를 증가시킴
    private func startBreakTimer() {
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onBreakTimerTick()
            }
        }
    }
    
    // 휴식이 끝났는지 확인
    private func onBreakTimerTick() {
        guard isBreakActive else { return }
        
        breakElapsed += 1
        
        // 선택한 시간을 넘겼는지 여부 체크 → 시각적 표시 등에 활용 가능
        if breakElapsed == breakPickedMinutes * 60 {
            showBreakEndOverlay = true  // "휴식 시간이 끝났어요" 알림 표시
        }
        
        // 사용자가 수동으로 종료할 때까지 계속 누적됨 (타이머는 멈추지 않음)
    }
    
    // 휴식 종료 시점에 BreakRecord를 만들고 기록
    func endBreak() {
        breakTimer?.invalidate()
        breakTimer = nil
        isBreakActive = false
        showBreakEndOverlay = true
        
        if let start = breakStartDate {
            let end = Date()
            let duration = end.timeIntervalSince(start)
            let isOver = duration > Double(breakPickedMinutes * 60)
            
            let record = BreakSession(start: start, end: end, isOverdue: isOver)
            
            // ✅ focusSession 연결
            record.session = focusSession
            
            // ✅ SwiftData에 저장
            modelContext.insert(record)
            
            // ✅ 현재 세션의 속성 갱신
            breakSessions.append(record)
            breakTotalSeconds += Int(duration)
        }
    }
    
    // 휴식을 종료하고 할 일을 다시 시작
    func endBreakAndResume() {
        endBreak()                  // 기존 휴식 종료 로직
        resumeCurrentTodo()        // 필요하다면 할 일 타이머 재시작
    }
    
    // MARK: - 초기화
    init(todoIDPairs: [(UUID, Int)], context: ModelContext, store: SessionStore) {
        self.modelContext = context
        self.store = store
        loadTodos(todoPairs: todoIDPairs, context: context)
    }
    
    // MARK: - Load Todos
    private func loadTodos(todoPairs: [(UUID, Int)], context: ModelContext) {
        var loaded: [DummyTodo] = []
        
        for (id, order) in todoPairs {
            if let todo = try? context.fetch(
                FetchDescriptor<Todo>(
                    predicate: #Predicate { $0.id == id }
                )
            ).first {
                let dummy = DummyTodo(
                    id: todo.id,
                    title: todo.title,
                    setTime: todo.setTime,
                    elapsed: 0,
                    isCompleted: false,
                    setSeconds: todo.setTime,
                    order: order
                )
                loaded.append(dummy)
            }
        }
        
        // ✅ 순서를 유지하기 위해 정렬하지 않고 그대로 할당
        self.todos = loaded
        self.currentIndex = 0
        
        if !todos.isEmpty {
            startTodoTimer()
        }
    }
    
    /// 리스트용 정렬: 완료가 위, 나머지는 기존 순서 유지
    var sortedTodosForListView: [DummyTodo] {
        // ✅ 1. 완료된 항목만 필터링
        let completed = todos.enumerated().filter { (offset, todo) in
            todo.isCompleted
        }
        
        // ✅ 2. 미완료 항목 필터링
        let remaining = todos.enumerated().filter { (offset, todo) in
            !todo.isCompleted
        }
        
        // ✅ 3. 완료된 항목은 선택 순서대로 정렬
        let sortedCompleted = completed.sorted { $0.offset < $1.offset }
        
        // ✅ 4. 순서를 유지한 후 element만 반환
        let result = (sortedCompleted + remaining).map { $0.element }
        
        return result
    }
    
    func selectTodo(at index: Int) {
        guard todos.indices.contains(index) else { return }
        currentIndex = index
        startTodoTimer()
    }
    
    // MARK: - Timer Logic
    
    /// 타이머 시작 함수
    /// - 이미 기존 타이머가 있다면 정지하고 새로 시작
    /// - 1초 간격으로 `onTodoTimerTick()` 호출
    private func startTodoTimer() {
        startFocusSessionIfNeeded() // ✅ 집중 세션이 없다면 생성
        
        todoTimer?.invalidate()
        todoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onTodoTimerTick()
            }
        }
    }
    
    /// 타이머 중지 함수
    /// - 타이머를 정지하고 `todoTimer`를 nil로 초기화
    func stopTimer() {
        todoTimer?.invalidate()
        todoTimer = nil
        isRunning = false
    }
    
    /// 일시 정지된 할 일을 다시 시작하는 함수
    /// - 현재 인덱스가 유효하고, 완료되지 않았으며, 타이머가 동작 중이 아닐 경우에만 타이머 재시작
    func resumeCurrentTodo() {
        guard todos.indices.contains(currentIndex) else { return }
        guard !todos[currentIndex].isCompleted else { return }
        guard todoTimer == nil else { return }
        
        startTodoTimer()
    }
    
    /// 매초 실행되는 타이머 Tick 함수
    /// - `elapsed`를 1초 증가시키고, 설정된 시간에 도달하면 해당 할 일을 완료 처리
    private func onTodoTimerTick() {
        guard todos.indices.contains(currentIndex) else { return }
        
        todos[currentIndex].elapsed += 1
        
        if todos[currentIndex].elapsed >= todos[currentIndex].setTime * 60 {
            completeCurrentTodo()
        }
    }
    
    /// 집중 세션(FocusSession)을 초기화하는 함수
    /// - 세션이 아직 생성되지 않았다면, 현재 시각을 시작 시점으로 하는 FocusSession을 생성
    /// - 생성된 세션은 SwiftData의 modelContext에 삽입되고, 뷰모델의 focusSession 프로퍼티에 저장됨
    /// - 집중모드의 시작을 기록하고, 이후 휴식 기록 등의 메타데이터를 연결하기 위한 준비 단계
    func startFocusSessionIfNeeded() {
        if focusSession == nil {
            let session = FocusSession(startedAt: Date(), endedAt: Date(), totalBreakSeconds: 0)
            modelContext.insert(session)
            focusSession = session
        }
    }
    
    // MARK: - Complete & Move to Next
    func completeCurrentTodo() {
        markTodoAsCompleted(at: currentIndex)
    }
    
    private func moveToNextTodo() {
        let next = todos.enumerated().first { !$0.element.isCompleted }
        if let (index, _) = next {
            currentIndex = index
            startTodoTimer()
        } else {
            // 모든 할 일 완료됨
            isRunning = false
        }
    }
    
    func markTodoAsCompleted(at index: Int) {
        guard todos.indices.contains(index) else { return }
        guard !todos[index].isCompleted else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            todos[index].isCompleted = true
        }
        
        // 현재 항목이면 타이머 정지 후 다음 항목으로 이동
        if index == currentIndex {
            stopTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.moveToNextTodo()
            }
        }
    }
    
    // MARK: - 세션 종료 처리
    func endFocusSession() {
        stopTimer()
        breakTimer?.invalidate()
        breakTimer = nil
        isRunning = false
        isBreakActive = false
        
        if let session = focusSession {
            session.endedAt = Date()
            session.totalBreakSeconds = breakTotalSeconds
            
            session.items = todos.map { todo in
                FocusItem(
                    title: todo.title,
                    setSeconds: todo.setSeconds,
                    elapsedSeconds: todo.elapsed,
                    isCompleted: todo.isCompleted,
                    order: todo.order
                )
            }
            
            session.breaks = breakSessions
            
            modelContext.insert(session)
            savedSession = session
            
            do {
                try modelContext.save()
            } catch {
                print("⚠️ 저장 실패: \(error.localizedDescription)")
            }
            
            shouldNavigateToReport = true
        }
    }
    
    func replaceStoreWithContext() {
        let store = SwiftDataSessionStore(context: modelContext)
        self.store = store
    }
    
    // MARK: - 텍스트
    /// 헤더 문구 계산(집중/휴식 자동 분기)
    var headerStatusText: String {
        if isBreakActive {
            let m = max(0, breakElapsed / 60)
            return "\(m)분째 휴식 중..."
        } else {
            return "\(elapsedTotalMinutes)분 째 탐사 중..."
        }
    }
    
    /// 원형 타이머 뷰에 전달할 "설정 시간(분)"
    /// - 휴식 중이면 휴식 분, 아니면 현재 할 일의 setTime
    var displaySetMinutes: Int {
        if isBreakActive { return breakTotalSeconds / 60 }
        return currentTodo?.setTime ?? 0
    }
    
    /// 원형 타이머 뷰에 전달할 "경과 시간(초)"
    /// - 휴식 중이면 휴식 경과, 아니면 현재 할 일의 경과
    var displayElapsedSeconds: Int {
        if isBreakActive { return breakElapsed }
        return currentTodo?.elapsed ?? 0
    }
    
    /// 남은 시간 문자열(집중/휴식 모두 대응)
    var remainingTimeString: String {
        if isBreakActive {
            let remaining = max(0, breakTotalSeconds - breakElapsed)
            return formatTime(seconds: remaining)
        } else {
            guard let currentTodo else { return "00:00" }
            let remaining = max(0, currentTodo.setTime * 60 - currentTodo.elapsed)
            return formatTime(seconds: remaining)
        }
    }
    
    /// 예상 종료 시간(집중 기준 계산. 휴식 중 표시 문구 교체는 View에서 처리 예정)
    var expectedEndTimeString: String {
        // 할 일 기준 남은 시간 (초)
        let taskRemainingSeconds = todos[currentIndex...].reduce(0) {
            $0 + max(0, ($1.setTime * 60 - $1.elapsed))
        }
        
        // 휴식 시간 포함
        let totalRemaining = taskRemainingSeconds + breakTotalSeconds
        
        let endDate = Date().addingTimeInterval(TimeInterval(totalRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: endDate)
    }
    
    /// 총 경과 시간(분) – 상단 "n분째 탐사 중" 등에 사용
    var elapsedTotalMinutes: Int {
        let seconds = todos.reduce(0) { $0 + $1.elapsed }
        return seconds / 60
    }
    
    // MARK: - 메모리 정리
    /// 메모리 누수 방지
    deinit {
        todoTimer?.invalidate()
        breakTimer?.invalidate()
    }
    
    // MARK: - Util
    private func formatTime(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
}
