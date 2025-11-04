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

    // MARK: - ❌ 수동 관리 제거 - MainViewModel에서 가져옴
    // @Published var parents: [Todo] = []
    
    // ✅ MainViewModel 참조
    weak var mainViewModel: MainViewModel?
    
    // ✅ Computed Property: MainViewModel의 데이터를 필터링
    var parents: [Todo] {
        guard let mainVM = mainViewModel else { return [] }
        return filterVisibleTodos(from: mainVM.parentTodos)
    }

    // MARK: - 상태
    @Published var showModal: Bool = false
    @Published var editingParent: Todo? = nil

    @Published var showAlert: Bool = false
    @Published var parentToDelete: Todo? = nil
    
    // MARK: - 완료 기준 시간 설정 (새벽 5시)
    @AppStorage("resetHour") private var resetHour: Int = 5

    // MARK: - SwiftData Context
    private var context: ModelContext
    
    init(context: ModelContext, mainViewModel: MainViewModel) {
        self.context = context
        self.mainViewModel = mainViewModel
    }

    // MARK: - 오늘 할 일 / 이전 할 일 필터링
    var todayParents: [Todo] {
        parents
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    var previousParents: [Todo] {
        parents
            .filter { !Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }
    
    // MARK: - 표시 가능한 Todo 필터링
    /// 완료 기준 시간을 고려하여 표시할 Todo만 필터링
    private func filterVisibleTodos(from todos: [Todo]) -> [Todo] {
        todos.filter { shouldShowCompletedTodo($0) }
    }
    
    // MARK: - 표시 가능한 자식 Todo 필터링
    func getVisibleChildren(of parent: Todo) -> [Todo] {
        parent.children.filter { shouldShowCompletedTodo($0) }
    }

    /// 할 일 정렬 기준: 완료여부 → order → 생성시간
    private func sortingRule(a: Todo, b: Todo) -> Bool {
        let left = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
        let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
        return left < right
    }

    // MARK: - 완료 할 일 표시 여부 판단
    private func shouldShowCompletedTodo(_ todo: Todo) -> Bool {
        // 미완료 항목은 항상 표시
        guard todo.isCompleted else { return true }
        
        // 완료 날짜가 없으면 표시하지 않음
        guard let performedDate = todo.performedDate else { return false }
        
        // 다음 리셋 시간 계산
        let nextResetTime = calculateNextResetTime(from: performedDate)
        return Date() < nextResetTime
    }

    /// 완료 시각으로부터 다음 리셋 시간 계산
    private func calculateNextResetTime(from performedDate: Date) -> Date {
        let calendar = Calendar.current
        
        var sameDayResetComponents = calendar.dateComponents([.year, .month, .day], from: performedDate)
        sameDayResetComponents.hour = resetHour
        sameDayResetComponents.minute = 0
        sameDayResetComponents.second = 0
        
        guard let sameDayResetTime = calendar.date(from: sameDayResetComponents) else {
            return performedDate
        }
        
        if performedDate < sameDayResetTime {
            return sameDayResetTime
        }
        
        guard let nextDayResetTime = calendar.date(byAdding: .day, value: 1, to: sameDayResetTime) else {
            return performedDate
        }
        
        return nextDayResetTime
    }

    // MARK: - 삭제 경고 호출
    func showDeleteAlert(for parent: Todo) {
        parentToDelete = parent
        showAlert = true
    }

    // MARK: - 삭제 수행
    func delete(parent: Todo, in context: ModelContext) {
        // 자식 Todo들도 함께 삭제
        for child in parent.children {
            context.delete(child)
        }
        
        context.delete(parent)
        
        do {
            try context.save()
            mainViewModel?.fetchTodos() // ✅ MainViewModel 갱신
            print("✅ Todo '\(parent.title)' 삭제 완료")
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
            mainViewModel?.fetchTodos() // ✅ MainViewModel 갱신
        } catch {
            print("❌ 재정렬 저장 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 모달 저장 로직
extension AddListViewModel {
    
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
            mainViewModel?.fetchTodos() // ✅ MainViewModel 갱신
        } catch {
            print("❌ 저장 실패: \(error.localizedDescription)")
        }
    }

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

        for child in existingChildren where !newTitles.contains(child.title) {
            context.delete(child)
        }

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

// MARK: - Todo 완료 처리
extension AddListViewModel {
    
    func toggleTodoCompletion(_ todo: Todo, context: ModelContext) {
        do {
            if todo.isCompleted {
                try todo.markAsIncomplete(context: context)
                
                if let parent = todo.parent, parent.isCompleted {
                    try parent.markAsIncomplete(context: context)
                }
            } else {
                try todo.markAsCompleted(context: context)
                
                if !todo.children.isEmpty {
                    for child in todo.children where !child.isCompleted {
                        try child.markAsCompleted(context: context)
                    }
                }
                
                if let parent = todo.parent {
                    let allSiblingsCompleted = parent.children.allSatisfy { $0.isCompleted }
                    if allSiblingsCompleted && !parent.isCompleted {
                        try parent.markAsCompleted(context: context)
                    }
                }
            }
            
            print("🔄 완료 상태 토글: \(todo.title) → \(todo.isCompleted)")
            
            // ✅ MainViewModel 갱신
            mainViewModel?.fetchTodos()
            
        } catch {
            print("❌ 완료 상태 토글 실패: \(error.localizedDescription)")
        }
    }
}
