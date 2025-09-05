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
    
    private var store: SessionStore
    
    // MARK: - 할 일 관련 상태
    @Published var todos: [DummyTodo] = []
    @Published var currentIndex: Int = 0
    @Published var isRunning: Bool = false
    
    private var todoTimer: Timer?
    
    // 현재 진행 중인 할 일(없을 수 있으니 Optional)
    var currentTodo: DummyTodo? {
        guard todos.indices.contains(currentIndex) else { return nil }
        return todos[currentIndex]
    }
    
    // MARK: - 휴식 관련 상태
    @Published var isBreakActive: Bool = false            // 현재 휴식 중인가?
    @Published var showBreakSheet: Bool = false           // 휴식 시간 선택 시트 표시 여부
    @Published var breakPickedMinutes: Int = 10           // 시트에서 고른 휴식 분 (5~30분)
    @Published private(set) var breakTotalSeconds: Int = 0// 휴식 총 시간 (초)
    @Published private(set) var breakElapsed: Int = 0     // 휴식 경과 시간 (초)
    @Published var showBreakEndOverlay: Bool = false      // 휴식 종료 오버레이 노출 여부
    
    @Published var breakSessions: [BreakSession] = []     // 휴식 기록
    
    private var breakTimer: Timer?
    private var breakStartDate: Date?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
            self?.onBreakTimerTick()
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
            modelContext.insert(record)
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
                    isCompleted: false
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
        todoTimer?.invalidate()
        todoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.onTodoTimerTick()
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
        
        for dummy in todos {
            if dummy.elapsed > 0 || dummy.isCompleted {
                do {
                    let result = try modelContext.fetch(
                        FetchDescriptor<Todo>(
                            predicate: #Predicate { $0.id == dummy.id }
                        )
                    )
                    if let todo = result.first {
                        todo.elapsedTime = dummy.elapsed
                        todo.isCompleted = dummy.isCompleted
                        todo.performedDate = Date()
                        try? modelContext.save()
                    }
                } catch {
                    print("⚠️ fetch 실패: \(error.localizedDescription)")
                }
            }
        }
        
        shouldNavigateToReport = true
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
