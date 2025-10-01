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
    
    // MARK: - 완료 기준 시간 설정 (새벽 5시)
    @AppStorage("resetHour") private var resetHour: Int = 5

    // MARK: - 오늘 할 일 / 이전 할 일 필터링
    var todayParents: [Todo] {
        filterVisibleTodos(from: parents)
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    var previousParents: [Todo] {
        filterVisibleTodos(from: parents)
            .filter { !Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }
    
    // MARK: - 완료 할 일 표시 여부 판단
    /// 완료된 할 일이 UI에 표시되어야 하는지 판단
    /// - Parameter todo: 확인할 Todo 객체
    /// - Returns: UI에 표시할 경우 true
    private func shouldShowCompletedTodo(_ todo: Todo) -> Bool {
        // 미완료 항목은 항상 표시
        guard todo.isCompleted else { return true }
        
        // 완료 날짜가 없으면 표시하지 않음
        guard let performedDate = todo.performedDate else { return false }
        
        // 리셋 기준 시간 계산
        let calendar = Calendar.current
        let now = Date()
        
        // 오늘의 리셋 시간 (새벽 5시)
        var todayResetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayResetComponents.hour = resetHour
        todayResetComponents.minute = 0
        todayResetComponents.second = 0
        
        guard let todayResetTime = calendar.date(from: todayResetComponents) else { return false }
        
        // 현재 시간이 오늘의 리셋 시간 이전이라면, 어제의 리셋 시간부터 확인
        let effectiveResetTime: Date
        if now < todayResetTime {
            // 어제의 리셋 시간을 기준으로 함
            effectiveResetTime = calendar.date(byAdding: .day, value: -1, to: todayResetTime) ?? todayResetTime
        } else {
            // 오늘의 리셋 시간을 기준으로 함
            effectiveResetTime = todayResetTime
        }
        
        // 완료 시간이 현재 기준 리셋 시간 이후인 경우만 표시
        return performedDate >= effectiveResetTime
    }
    
    // MARK: - 표시 가능한 Todo 필터링
    /// 완료 기준 시간을 고려하여 표시할 Todo만 필터링
    private func filterVisibleTodos(from todos: [Todo]) -> [Todo] {
        todos.compactMap { parent in
            // 부모가 완료되었는데 표시 기간이 지났으면 제외
            guard shouldShowCompletedTodo(parent) else { return nil }
            
            // 부모가 미완료인 경우는 자식 상태와 관계없이 항상 표시
            // (자식이 모두 완료되어 숨겨져도 부모는 계속 보임)
            
            return parent
        }
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
