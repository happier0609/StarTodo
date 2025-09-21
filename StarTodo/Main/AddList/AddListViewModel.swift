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

    // MARK: - 수동 관리할 부모 Todo 목록
    @Published var parents: [Todo] = []

    // MARK: - 상태
    @Published var showModal: Bool = false
    @Published var editingParent: Todo? = nil

    @Published var showAlert: Bool = false
    @Published var parentToDelete: Todo? = nil

    // MARK: - 오늘 할 일 / 이전 할 일 필터링
    var todayParents: [Todo] {
        parents.filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    var previousParents: [Todo] {
        parents.filter { !Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    /// 할 일 정렬 기준: 완료여부 → order → 생성시간
    private func sortingRule(a: Todo, b: Todo) -> Bool {
        let left = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
        let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
        return left < right
    }

    // MARK: - ✨ 부모 Todo 목록 갱신 (핵심 메서드)
    func fetchParents(with context: ModelContext) {
        do {
            // SwiftData에서는 정렬을 직접 처리하는 것이 더 안정적
            let descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { todo in
                    todo.parent == nil
                }
            )
            let fetchedTodos = try context.fetch(descriptor)
            
            // 수동으로 정렬 적용
            parents = fetchedTodos.sorted { a, b in
                // 1. 완료 여부 (미완료가 먼저)
                if a.isCompleted != b.isCompleted {
                    return !a.isCompleted && b.isCompleted
                }
                // 2. order 순서
                if a.order != b.order {
                    return a.order < b.order
                }
                // 3. 생성 시간
                return a.createdAt < b.createdAt
            }
        } catch {
            print("❌ Todo fetch 실패: \(error.localizedDescription)")
            parents = []
        }
    }

    // MARK: - 부모 할 일 fetch (async 버전 - 필요시 사용)
    func fetchParentTodos(context: ModelContext) async throws -> [Todo] {
        let descriptor = FetchDescriptor<Todo>(
            predicate: #Predicate { todo in
                todo.parent == nil
            }
        )
        let fetchedTodos = try context.fetch(descriptor)
        
        return fetchedTodos.sorted { a, b in
            if a.isCompleted != b.isCompleted {
                return !a.isCompleted && b.isCompleted
            }
            if a.order != b.order {
                return a.order < b.order
            }
            return a.createdAt < b.createdAt
        }
    }

    // MARK: - 삭제 경고 호출
    func showDeleteAlert(for parent: Todo) {
        parentToDelete = parent
        showAlert = true
    }

    // MARK: - 삭제 수행
    func delete(parent: Todo, in context: ModelContext) {
        context.delete(parent)
        do {
            try context.save()
            fetchParents(with: context) // 삭제 후 목록 갱신
        } catch {
            print("❌ 삭제 저장 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 순서 재배치
    func reorderRootTodos(from: IndexSet, to destination: Int, in context: ModelContext) {
        var items = parents.sorted { $0.order < $1.order }
        items.move(fromOffsets: from, toOffset: destination)
        for (i, t) in items.enumerated() {
            t.order = i
        }
        do {
            try context.save()
            fetchParents(with: context) // 재정렬 후 목록 갱신
        } catch {
            print("❌ 재정렬 저장 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 모달 저장 로직 (신규 추가 또는 편집)
extension AddListViewModel {
    
    /// 부모 Todo를 저장 (추가 또는 수정)
    func saveTodo(
        editingParent: Todo?,
        title: String,
        children: [String],
        context: ModelContext
    ) {
        if let todo = editingParent {
            updateTodo(todo, with: title, children: children, context: context)
        } else {
            createTodo(with: title, children: children, context: context)
        }

        do {
            try context.save()
            fetchParents(with: context)
        } catch {
            print("❌ 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 기존 Todo 수정
    private func updateTodo(
        _ todo: Todo,
        with title: String,
        children: [String],
        context: ModelContext
    ) {
        todo.title = title

        let existingChildren = todo.children
        let existingTitles = Set(existingChildren.map(\.title))
        let newTitles = Set(children)

        // ⛔️ 기존에는 없고, 새 목록에도 없는 → 삭제 대상
        for child in existingChildren where !newTitles.contains(child.title) {
            context.delete(child)
        }

        // ✅ 새로 추가될 자식만 필터링
        let toAdd = children.filter { !existingTitles.contains($0) }
        let startOrder = (todo.children.map(\.order).max() ?? -1) + 1

        for (offset, raw) in toAdd.enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let child = Todo(
                title: trimmed,
                isCompleted: false,
                setTime: todo.setTime,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: startOrder + offset,
                parent: todo
            )
            todo.children.append(child)
        }
    }

    /// 새로운 Todo 생성
    private func createTodo(
        with title: String,
        children: [String],
        context: ModelContext
    ) {
        let nextOrder = (parents.map(\.order).max() ?? -1) + 1

        let parent = Todo(
            title: title,
            isCompleted: false,
            setTime: 25,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: nextOrder,
            parent: nil
        )

        for (i, raw) in children.enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let child = Todo(
                title: trimmed,
                isCompleted: false,
                setTime: 25,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: i,
                parent: parent
            )
            parent.children.append(child)
        }

        context.insert(parent)
    }
}
