//
//  FocusSettingViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/29/25.
//

import Foundation
import SwiftData

/// 집중모드 설정 화면의 선택/확장/시간 상태만 관리(데이터 저장 X)
@MainActor
final class FocusSettingViewModel: ObservableObject {
    // 선택된 항목의 id (부모/자식 모두 포함)
    @Published var selectedIDs: Set<UUID> = []

    // 펼쳐진 부모 id
    @Published var expandedParentIDs: Set<UUID> = []

    // 화면에 보여줄 "부모" 목록 (SwiftData 모델)
    @Published var focusParents: [Todo] = []

    // 각 항목의 설정 시간(분). 값이 없으면 Todo.setTime 사용
    @Published var overrideMinutes: [UUID: Int] = [:]

    // MARK: - Load
    /// 완료되지 않은 부모만 세팅
    func loadFrom(_ parents: [Todo]) {
        self.focusParents = parents.filter { $0.parent == nil && !$0.isCompleted }
        // 필요시 정렬: order -> createdAt
        self.focusParents.sort {
            ($0.order, $0.createdAt) < ($1.order, $1.createdAt)
        }
    }

    // MARK: - Expand / Select
    func toggleExpanded(for parent: Todo) {
        let id = parent.id
        if expandedParentIDs.contains(id) { expandedParentIDs.remove(id) }
        else { expandedParentIDs.insert(id) }
    }

    func isExpanded(_ parent: Todo) -> Bool {
        expandedParentIDs.contains(parent.id)
    }

    /// 부모를 토글하면 부모+자식 전체 토글
    func toggleSelection(for parent: Todo) {
        let allIDs: [UUID] = [parent.id] + parent.children.map(\.id)
        let shouldSelect = !allIDs.allSatisfy { selectedIDs.contains($0) }
        if shouldSelect {
            selectedIDs.formUnion(allIDs)
        } else {
            for id in allIDs { selectedIDs.remove(id) }
        }
    }

    func toggleChild(_ child: Todo) {
        if selectedIDs.contains(child.id) { selectedIDs.remove(child.id) }
        else { selectedIDs.insert(child.id) }
    }

    func isSelected(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return selectedIDs.contains(id)
    }

    // MARK: - Time
    func minutes(for todo: Todo) -> Int {
        overrideMinutes[todo.id] ?? todo.setTime
    }
    func setMinutes(_ m: Int, for todo: Todo) {
        overrideMinutes[todo.id] = m
    }

    // MARK: - 결과 묶기 (FocusMode로 넘길 데이터)
    /// 선택된 항목만 (부모/자식 합쳐서) 반환
    func pickedTodos(from allParents: [Todo]) -> [Todo] {
        var result: [Todo] = []
        for p in allParents {
            if isSelected(p.id) { result.append(p) }
            for c in p.children {
                if isSelected(c.id) { result.append(c) }
            }
        }
        return result
    }

    /// FocusMode에 넘길 `(UUID, minutes)` 페이로드
    func payload() -> [(UUID, Int)] {
        pickedTodos(from: focusParents).map { ($0.id, minutes(for: $0)) }
    }
}
