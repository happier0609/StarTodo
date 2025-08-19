//
//  FocusModeViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

//MARK: - 코어데이터 걷어낸 코드
import Foundation
import SwiftUI

@MainActor
class FocusModeViewModel: ObservableObject {
    // MARK: - 집중(할 일) 관련 상태
    @Published var todos: [DummyTodo] = []
    @Published var currentIndex: Int = 0
    
    // MARK: - 휴식 관련 상태
    @Published var isBreakActive: Bool = false            // 현재 휴식 중인가?
    @Published var showBreakSheet: Bool = false           // 휴식 시간 선택 시트 표시 여부
    @Published var breakPickedMinutes: Int = 10           // 시트에서 고른 휴식 분(5~30분 중)
    @Published private(set) var breakTotalSeconds: Int = 0// 휴식 총 시간(초)
    @Published private(set) var breakElapsed: Int = 0     // 휴식 경과 시간(초)
    @Published var showBreakEndOverlay: Bool = false        // 휴식 종료 오버레이 노출용

    // MARK: - 이동/리포트
    @Published var shouldNavigateToReport: Bool = false
    @Published var reportData: [DummyTodo] = []

    // MARK: - 내부 타이머
    private var timer: Timer?
    private var lastTick: Date = Date()

    // MARK: - 초기화
    init(dummyTodos: [DummyTodo]) {
        self.todos = dummyTodos

        // 프리뷰에서는 실제 타이머 돌지 않도록
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            startTimer()
        }
    }

    // 현재 진행 중인 할 일(없을 수 있으니 Optional)
    var currentTodo: DummyTodo? {
        guard todos.indices.contains(currentIndex) else { return nil }
        return todos[currentIndex]
    }

    // MARK: - 표시용(집중/휴식 공용) 프로퍼티
    
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
        let totalRemaining = todos[currentIndex...].reduce(0) {
            $0 + max(0, ($1.setTime * 60 - $1.elapsed))
        }
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
    
    /// 리스트용 정렬: 완료가 위, 나머지는 기존 순서 유지
    var sortedTodosForListView: [DummyTodo] {
        let completed = todos.enumerated()
            .filter { $0.element.isCompleted }
            .sorted { $0.offset < $1.offset } // 완료된 순서 유지

        let remaining = todos.enumerated()
            .filter { !$0.element.isCompleted }

        return (completed + remaining).map { $0.element }
    }

    // MARK: - 타이머 제어
    func startTimer() {
        stopTimer()
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 1초마다 호출되는 틱 – 휴식/집중을 분기 처리
    private func tick() {
        let now = Date()
        let delta = Int(now.timeIntervalSince(lastTick))
        lastTick = now

        // 🔹 휴식 타이머 진행
        if isBreakActive {
            breakElapsed += delta
            if breakElapsed >= breakTotalSeconds {
                handleBreakFinished()  // TODO: Step 5에서 알림/안내창 붙이기
            }
            return
        }

        // 🔹 집중 타이머 진행
        guard todos.indices.contains(currentIndex) else { return }
        todos[currentIndex].elapsed += delta

        if todos[currentIndex].elapsed >= todos[currentIndex].setTime * 60 {
            markCurrentTodoAsCompleted()
        }
    }

    // MARK: - 휴식 제어 API
    /// 휴식 시작: 현재 집중 타이머를 멈추고 휴식 타이머로 전환
    func startBreak(minutes: Int) {
        stopTimer()
        isBreakActive = true
        breakTotalSeconds = minutes * 60
        breakElapsed = 0
        startTimer()
    }

    /// 휴식 중단 후 다시 집중 재개
    func endBreakAndResume() {
        isBreakActive = false
        startTimer()
    }

    /// 휴식 종료 처리에서 오버레이 띄우기
    private func handleBreakFinished() {
        isBreakActive = false
        stopTimer()
        showBreakEndOverlay = true        // ← 오버레이 ON
        // (버튼 누르면 endBreakAndResume()로 재개)
    }

    // MARK: - 집중(할 일) 흐름
    func markCurrentTodoAsCompleted() {
        guard todos.indices.contains(currentIndex) else { return }
        todos[currentIndex].isCompleted = true
        stopTimer()

        // 2초 후 다음 항목 이동(연출용)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.moveToNextTodo()
        }
    }
    
    /// 특정 id의 항목을 완료 처리(리스트에서 개별 완료 시 사용)
    func markTodoAsCompleted(id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isCompleted = true

        // 현재 항목을 완료했다면 흐름 이어서 진행
        if index == currentIndex {
            moveToNextTodo()
        }
    }
    
    /// 다음 작업으로 이동: "남아있는 항목 중 가장 위"를 선택
    func moveToNextTodo() {
        if let nextIndex = todos.firstIndex(where: { !$0.isCompleted }) {
            currentIndex = nextIndex
            startTimer()
        } else {
            endFocusSession()
        }
    }

    func endFocusSession() {
        stopTimer()
        reportData = todos
        shouldNavigateToReport = true
    }
    
    /// 리스트에서 특정 인덱스를 눌렀을 때 해당 작업으로 이동
    func selectTodo(at index: Int) {
        guard index != currentIndex,
              todos.indices.contains(index),
              !todos[index].isCompleted else { return }

        stopTimer()
        currentIndex = index
        startTimer()
    }

    // MARK: - Util
    private func formatTime(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}


//MARK: - 기존 코드 접어두기
//import SwiftUI
//import Foundation
//
//// 개별 할일 상태 모델
//struct FocusTodoState {
//    let todo: TodoEntity              // CoreData의 원본 할일 객체
//    var setTime: Int                 // 설정한 집중 시간 (분)
//    var elapsed: Int                 // 경과 시간 (초)
//    var isCompleted: Bool            // 완료 여부
//}
//
//@MainActor
//class FocusModeViewModel: ObservableObject {
//    // 전체 집중 할일 상태
//    @Published var todoStates: [FocusTodoState] = []
//    
//    // 현재 진행 중인 인덱스
//    @Published var currentIndex: Int = 0
//    
//    // 휴식 상태
//    @Published var isBreakActive: Bool = false
//    
//    // 휴식 설정 시트 표시 여부
//    @Published var showBreakSheet: Bool = false
//    
//    @Published var shouldNavigateToReport: Bool = false
//    @Published var reportData: [FocusTodoState] = []
//    
//    // 내부 타이머 관련
//    private var timer: Timer?
//    private var lastTick: Date = Date()
//    
//    // MARK: - 초기화
//    // 일반 실행용 초기화자
//    init(todoIDPairs: [(UUID, Int)]) {
//        self.todoStates = todoIDPairs.compactMap { id, time in
//            if let todo = CoreDataManager.shared.fetchTodo(by: id) {
//                return FocusTodoState(todo: todo, setTime: time, elapsed: 0, isCompleted: false)
//            }
//            return nil
//        }
//
//        // 프리뷰 환경이 아닐 때만 타이머 시작
//        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
//            startTimer()
//        }
//    }
//
//    // 프리뷰 전용 초기화자
//    init(previewTodos: [TodoEntity]) {
//        self.todoStates = previewTodos.map {
//            FocusTodoState(
//                todo: $0,
//                setTime: Int($0.setTime),
//                elapsed: 0,
//                isCompleted: false
//            )
//        }
//    }
//    
//    // 현재 할일 가져오기
//    var currentTodo: FocusTodoState {
//        guard currentIndex < todoStates.count else {
//            return FocusTodoState(todo: .init(), setTime: 0, elapsed: 0, isCompleted: true)
//        }
//        return todoStates[currentIndex]
//    }
//    
//    // 남은 시간 문자열
//    var remainingTimeString: String {
//        let remaining = max(0, currentTodo.setTime * 60 - currentTodo.elapsed)
//        return formatTime(seconds: remaining)
//    }
//    
//    // 예상 종료 시간
//    var expectedEndTimeString: String {
//        let totalRemaining = todoStates[currentIndex...].reduce(0) {
//            $0 + max(0, ($1.setTime * 60 - $1.elapsed))
//        }
//        let endDate = Date().addingTimeInterval(TimeInterval(totalRemaining))
//        let formatter = DateFormatter()
//        formatter.dateFormat = "a h:mm"
//        formatter.locale = Locale(identifier: "ko_KR")
//        return formatter.string(from: endDate)
//    }
//    
//    var elapsedTotalMinutes: Int {
//        let seconds = todoStates.reduce(0) { $0 + $1.elapsed }
//        return seconds / 60
//    }
//    
//    // 타이머 시작
//    func startTimer() {
//        stopTimer()
//        lastTick = Date()
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            self?.tick()
//        }
//    }
//    
//    // 타이머 멈춤
//    func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    // 1초마다 호출
//    private func tick() {
//        guard !isBreakActive else { return }
//        
//        let now = Date()
//        let delta = Int(now.timeIntervalSince(lastTick))
//        lastTick = now
//        
//        todoStates[currentIndex].elapsed += delta
//        
//        if todoStates[currentIndex].elapsed >= todoStates[currentIndex].setTime * 60 {
//            markCurrentTodoAsCompleted()
//        }
//    }
//    
//    // 현재 할일 완료 처리
//    func markCurrentTodoAsCompleted() {
//        guard currentIndex < todoStates.count else { return }
//        todoStates[currentIndex].isCompleted = true
//        stopTimer()
//        
//        // 2초 지연 후 다음 항목으로
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            if self.currentIndex + 1 < self.todoStates.count {
//                self.currentIndex += 1
//                self.startTimer()
//            } else {
//                // 모든 할일 완료 → ReportView 이동 등 처리
//            }
//        }
//    }
//    
//    func endFocusSession() {
//        stopTimer()
//        reportData = todoStates
//        shouldNavigateToReport = true
//    }
//    
//    // 시간 포맷터 (mm:ss)
//    private func formatTime(seconds: Int) -> String {
//        String(format: "%02d:%02d", seconds / 60, seconds % 60)
//    }
//}
