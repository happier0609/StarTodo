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

    // MARK: - 초기화
    init(todoPairs: [(UUID, Int)], modelContext: ModelContext) {
        loadTodos(todoPairs: todoPairs, context: modelContext)
    }

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

        self.todos = loaded
    }

    // MARK: - 현재 할 일 완료 처리 및 다음 항목 이동
    func markCurrentAsCompleted() {
        guard todos.indices.contains(currentIndex) else { return }
        todos[currentIndex].isCompleted = true

        // 다음 할 일로 이동 (남은 항목 중 가장 앞)
        if let nextIndex = todos.firstIndex(where: { !$0.isCompleted }) {
            currentIndex = nextIndex
        } else {
            // 모든 항목 완료됨
            currentIndex = -1
        }
    }

    // MARK: - 현재 할 일 시간 업데이트
    func updateElapsed(seconds: Int) {
        guard todos.indices.contains(currentIndex) else { return }
        todos[currentIndex].elapsed = seconds
    }

    var currentTodo: DummyTodo? {
        guard todos.indices.contains(currentIndex) else { return nil }
        return todos[currentIndex]
    }
}
