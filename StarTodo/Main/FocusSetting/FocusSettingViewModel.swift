//
//  FocusSettingViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/29/25.
//

import Foundation
import SwiftUI
import CoreData

/// 집중모드 설정 화면에서 선택된 할 일과 확장 상태를 관리하는 뷰모델
class FocusSettingViewModel: ObservableObject {
    // 선택된 할 일의 UUID 목록
    @Published var selectedTodoIDs: Set<UUID> = []

    // 확장된 상위 항목의 UUID 목록
    @Published var expandedParentIDs: Set<UUID> = []

    // 표시할 상위 할 일 목록
    @Published var focusTodoGroups: [TodoEntity] = []

    // ✅ 완료되지 않은 할 일들 중 상위 항목만 필터링하여 불러오기
    func loadUncompletedFrom(_ todos: [TodoEntity]) {
        self.focusTodoGroups = todos.filter { $0.parent == nil && !$0.isCompleted }
    }

    // ✅ 상위 항목 전체 토글 (하위 포함)
    func toggleSelection(for parent: TodoEntity) {
        let allIDs = [parent.id].compactMap { $0 } + parent.childrenArray.compactMap { $0.id }

        if isSelected(parent.id) {
            selectedTodoIDs.subtract(allIDs)  // 전체 해제
        } else {
            selectedTodoIDs.formUnion(allIDs) // 전체 선택
        }
    }

    // ✅ 상위 항목 확장/접기 토글
    func toggleExpanded(for parent: TodoEntity) {
        guard let id = parent.id else { return }

        if expandedParentIDs.contains(id) {
            expandedParentIDs.remove(id)
        } else {
            expandedParentIDs.insert(id)
        }
    }

    // ✅ 해당 UUID가 확장 상태인지 여부 반환
    func isExpanded(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return expandedParentIDs.contains(id)
    }

    // ✅ 해당 UUID가 선택되었는지 여부 반환
    func isSelected(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return selectedTodoIDs.contains(id)
    }

    // ✅ 선택된 항목만 반환 (다음 화면에 전달하기 위함)
    func selectedTodos(from allTodos: [TodoEntity]) -> [TodoEntity] {
        allTodos.filter { todo in
            if let id = todo.id {
                return selectedTodoIDs.contains(id)
            }
            return false
        }
    }
}
