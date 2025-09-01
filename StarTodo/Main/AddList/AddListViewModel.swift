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
