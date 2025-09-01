//
//  FocusSettingViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/29/25.
//

/// 역할: 선택된 할 일 관리, 선택/해제 로직, 시간 설정, 집중 모드 전환

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class FocusSettingViewModel: ObservableObject {
    
    // MARK: - 선택된 할 일 목록
    @Published var selectedTodos: [Todo] = []
    @Published var selectedIDs: [UUID] = []

    // MARK: - 시간 설정 (id: 분 단위)
    @Published var timeSettings: [UUID: Int] = [:]

    // MARK: - 집중 모드 진입용
    @Published var selectedFocusTodos: [Todo] = []

    // MARK: - 선택 여부 확인
    func isSelected(_ todo: Todo) -> Bool {
        selectedIDs.contains(todo.id)
    }

    // MARK: - 선택/해제 토글
    func toggleSelection(of todo: Todo) {
        if isSelected(todo) {
            selectedTodos.removeAll { $0.id == todo.id }
            selectedIDs.removeAll { $0 == todo.id }
        } else {
            selectedTodos.append(todo)
            selectedIDs.append(todo.id)
        }
    }

    func clearSelections() {
        selectedTodos.removeAll()
        selectedIDs.removeAll()
    }

    // MARK: - 부모 항목 선택/해제 (자식 포함)
    func toggleParentSelection(_ parent: Todo, _ select: Bool) {
        let ids = [parent.id] + parent.children.map(\.id)

        if select {
            selectedIDs = Array(Set(selectedIDs + ids))
            for t in [parent] + parent.children where !selectedTodos.contains(where: { $0.id == t.id }) {
                selectedTodos.append(t)
            }
        } else {
            selectedIDs.removeAll { ids.contains($0) }
            selectedTodos.removeAll { ids.contains($0.id) }
        }
    }

    // MARK: - 자식 항목 선택/해제
    func toggleChildSelection(_ child: Todo, _ select: Bool) {
        if select {
            if !selectedIDs.contains(child.id) { selectedIDs.append(child.id) }
            if !selectedTodos.contains(where: { $0.id == child.id }) { selectedTodos.append(child) }
        } else {
            selectedIDs.removeAll { $0 == child.id }
            selectedTodos.removeAll { $0.id == child.id }
        }
    }

    // MARK: - 시간 설정 (임시 캐시)
    func setTime(for todo: Todo) -> Int {
        timeSettings[todo.id] ?? todo.setTime
    }

    func updateSetTime(for todo: Todo, minutes: Int) {
        timeSettings[todo.id] = minutes
    }

    // MARK: - 다음 단계로 이동 준비
    func prepareFocusTarget() {
        selectedFocusTodos = selectedTodos.filter { selectedIDs.contains($0.id) }
    }
}
