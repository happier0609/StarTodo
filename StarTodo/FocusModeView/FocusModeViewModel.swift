//
//  FocusModeViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI
import Foundation

// 개별 할일 상태 모델
struct FocusTodoState {
    let todo: TodoEntity              // CoreData의 원본 할일 객체
    var setTime: Int                 // 설정한 집중 시간 (분)
    var elapsed: Int                 // 경과 시간 (초)
    var isCompleted: Bool            // 완료 여부
}

@MainActor
class FocusModeViewModel: ObservableObject {
    // 전체 집중 할일 상태
    @Published var todoStates: [FocusTodoState] = []
    
    // 현재 진행 중인 인덱스
    @Published var currentIndex: Int = 0
    
    // 휴식 상태
    @Published var isBreakActive: Bool = false
    
    // 휴식 설정 시트 표시 여부
    @Published var showBreakSheet: Bool = false
    
    @Published var shouldNavigateToReport: Bool = false
    @Published var reportData: [FocusTodoState] = []
    
    // 내부 타이머 관련
    private var timer: Timer?
    private var lastTick: Date = Date()
    
    // MARK: - 초기화
    init(todoIDPairs: [(UUID, Int)]) {
        self.todoStates = todoIDPairs.compactMap { id, time in
            if let todo = CoreDataManager.shared.fetchTodo(by: id) {
                return FocusTodoState(todo: todo, setTime: time, elapsed: 0, isCompleted: false)
            }
            return nil
        }
        startTimer()
    }
    
    init(viewModel: FocusModeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // 현재 할일 가져오기
    var currentTodo: FocusTodoState {
        guard currentIndex < todoStates.count else {
            return FocusTodoState(todo: .init(), setTime: 0, elapsed: 0, isCompleted: true)
        }
        return todoStates[currentIndex]
    }
    
    // 남은 시간 문자열
    var remainingTimeString: String {
        let remaining = max(0, currentTodo.setTime * 60 - currentTodo.elapsed)
        return formatTime(seconds: remaining)
    }
    
    // 예상 종료 시간
    var expectedEndTimeString: String {
        let totalRemaining = todoStates[currentIndex...].reduce(0) {
            $0 + max(0, ($1.setTime * 60 - $1.elapsed))
        }
        let endDate = Date().addingTimeInterval(TimeInterval(totalRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: endDate)
    }
    
    var elapsedTotalMinutes: Int {
        let seconds = todoStates.reduce(0) { $0 + $1.elapsed }
        return seconds / 60
    }
    
    // 타이머 시작
    func startTimer() {
        stopTimer()
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    // 타이머 멈춤
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // 1초마다 호출
    private func tick() {
        guard !isBreakActive else { return }
        
        let now = Date()
        let delta = Int(now.timeIntervalSince(lastTick))
        lastTick = now
        
        todoStates[currentIndex].elapsed += delta
        
        if todoStates[currentIndex].elapsed >= todoStates[currentIndex].setTime * 60 {
            markCurrentTodoAsCompleted()
        }
    }
    
    // 현재 할일 완료 처리
    func markCurrentTodoAsCompleted() {
        guard currentIndex < todoStates.count else { return }
        todoStates[currentIndex].isCompleted = true
        stopTimer()
        
        // 2초 지연 후 다음 항목으로
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.currentIndex + 1 < self.todoStates.count {
                self.currentIndex += 1
                self.startTimer()
            } else {
                // 모든 할일 완료 → ReportView 이동 등 처리
            }
        }
    }
    
    func endFocusSession() {
        stopTimer()
        reportData = todoStates
        shouldNavigateToReport = true
    }
    
    // 시간 포맷터 (mm:ss)
    private func formatTime(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
