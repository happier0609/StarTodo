//
//  AddListViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/1/25.
//


/// 역할: 할 일 목록 필터링 (오늘/이전), 삭제, 추가/편집 모달

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AddListViewModel: ObservableObject {
    
    // MARK: - 쿼리 (부모 할 일만)
    @Query(filter: #Predicate<Todo> { $0.parent == nil })
    var parents: [Todo]

    // MARK: - 상태
    @Published var showModal: Bool = false
    @Published var editingParent: Todo? = nil
    
    @Published var showAlert: Bool = false
    @Published var parentToDelete: Todo? = nil

    // MARK: - 분류된 할 일 목록
    var todayParents: [Todo] {
        parents.filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    var previousParents: [Todo] {
        parents.filter { !Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    private func sortingRule(a: Todo, b: Todo) -> Bool {
        let left = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
        let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
        return left < right
    }

    // MARK: - 삭제 경고 호출
    func showDeleteAlert(for parent: Todo) {
        parentToDelete = parent
        showAlert = true
    }

    // MARK: - 삭제 수행
    func delete(parent: Todo, in context: ModelContext) {
        context.delete(parent)
    }

    // MARK: - 순서 재배치
    func reorderRootTodos(from: IndexSet, to destination: Int, in context: ModelContext) {
        var items = parents.sorted { $0.order < $1.order }
        items.move(fromOffsets: from, toOffset: destination)
        for (i, t) in items.enumerated() {
            t.order = i
        }
    }
}


/// 모달용
extension AddListViewModel {
    func saveTodo(
        editingParent: Todo?,
        title: String,
        children: [String],
        context: ModelContext
    ) {
        if let todo = editingParent {
            // 수정
            todo.title = title

            let existing = todo.children
            let existingTitles = Set(existing.map(\.title))
            let newTitleSet = Set(children)

            // 삭제될 자식
            for child in existing where !newTitleSet.contains(child.title) {
                context.delete(child)
            }

            // 새로 추가될 자식
            let toAdd = children.filter { !existingTitles.contains($0) }
            let startOrder = (todo.children.map(\.order).max() ?? -1) + 1
            for (offset, raw) in toAdd.enumerated() {
                let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { continue }
                let child = Todo(title: t,
                                 isCompleted: false,
                                 setTime: todo.setTime,
                                 elapsedTime: 0,
                                 createdAt: .now,
                                 performedDate: nil,
                                 order: startOrder + offset,
                                 parent: todo)
                todo.children.append(child)
            }
        } else {
            // 추가
            let nextOrder = (parents.map(\.order).max() ?? -1) + 1
            let parent = Todo(title: title,
                              isCompleted: false,
                              setTime: 25,
                              elapsedTime: 0,
                              createdAt: .now,
                              performedDate: nil,
                              order: nextOrder,
                              parent: nil)

            for (i, raw) in children.enumerated() {
                let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { continue }
                let child = Todo(title: t,
                                 isCompleted: false,
                                 setTime: 25,
                                 elapsedTime: 0,
                                 createdAt: .now,
                                 performedDate: nil,
                                 order: i,
                                 parent: parent)
                parent.children.append(child)
            }

            context.insert(parent)
        }
    }
}
