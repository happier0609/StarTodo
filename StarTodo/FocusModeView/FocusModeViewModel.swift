//
//  FocusModeViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
import SwiftData

@MainActor
final class FocusModeViewModel: ObservableObject {
    // MARK: - 할 일 관련 상태
    @Published var todos: [DummyTodo] = []
    @Published var currentIndex: Int = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    private let context: ModelContext
    
    // MARK: - 초기화
    init(todoIDPairs: [(UUID, Int)], context: ModelContext) {
        self.context = context
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
        
        self.todos = loaded.sorted { $0.setTime < $1.setTime }
        self.currentIndex = 0
        
        if !todos.isEmpty {
            startTimer()
        }
    }
    
    // MARK: - Timer Logic
    func startTimer() {
        guard !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { await self?.updateElapsed() }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func updateElapsed() {
        guard todos.indices.contains(currentIndex) else { return }
        todos[currentIndex].elapsed += 1
        
        if todos[currentIndex].elapsed >= todos[currentIndex].setTime * 60 {
            completeCurrentTodo()
        }
    }
    
    // MARK: - Complete & Move to Next
    func completeCurrentTodo() {
        guard todos.indices.contains(currentIndex) else { return }
        
        todos[currentIndex].isCompleted = true
        stopTimer()
        moveToNextTodo()
    }
    
    private func moveToNextTodo() {
        let next = todos.enumerated().first { !$0.element.isCompleted }
        if let (index, _) = next {
            currentIndex = index
            startTimer()
        } else {
            // 모든 할 일 완료됨
            isRunning = false
        }
    }
}
