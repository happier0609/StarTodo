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

/// 집중 모드 설정 화면(FocusSettingView)을 위한 ViewModel
@MainActor
final class FocusSettingViewModel: ObservableObject {

    // MARK: - ✅ MainViewModel 참조
    weak var mainViewModel: MainViewModel?
    
    // MARK: - ❌ 수동 관리 제거 - MainViewModel에서 가져옴
    // @Published var focusParents: [Todo] = []
    
    // ✅ Computed Property: MainViewModel의 데이터 사용
    var focusParents: [Todo] {
        guard let mainVM = mainViewModel else { return [] }
        return mainVM.uncompletedParentTodos
    }

    // MARK: - 선택된 할 일 목록
    @Published var selectedTodos: [Todo] = []
    @Published var selectedIDs: [UUID] = []
    
    // MARK: - 시간 설정 캐시
    @Published var timeSettings: [UUID: Int] = [:]
    
    // MARK: - 집중 모드 진입용 데이터
    @Published var selectedFocusTodos: [Todo] = []
    
    // MARK: - 확장/접기 상태 관리
    @Published var expandedParentIDs: Set<UUID> = []
    
    func isExpanded(_ parent: Todo) -> Bool {
        expandedParentIDs.contains(parent.id)
    }
    
    func toggleExpanded(for parent: Todo) {
        if expandedParentIDs.contains(parent.id) {
            expandedParentIDs.remove(parent.id)
        } else {
            expandedParentIDs.insert(parent.id)
        }
    }
    
    // MARK: - 부모 카드 확장 상태 초기화
    func resetExpansionStates() {
        expandedParentIDs.removeAll()
    }

    // MARK: - 선택 여부 확인
    func isSelected(_ todo: Todo) -> Bool {
        selectedIDs.contains(todo.id)
    }

    func isSelected(_ id: UUID) -> Bool {
        selectedIDs.contains(id)
    }

    // MARK: - 선택/해제 토글
    func toggleSelection(of todo: Todo) {
        // ✅ 완료된 항목은 선택 불가
        if todo.isCompleted {
            print("⚠️ 완료된 항목은 선택할 수 없습니다: \(todo.title)")
            return
        }
        
        // ✅ 선택 전 완료된 항목 정리
        cleanupCompletedSelections()
        
        if todo.parent == nil {
            let isCurrentlySelected = isSelected(todo)
            
            // 자식이 없는 부모: 부모만 토글
            if todo.children.isEmpty {
                if isCurrentlySelected {
                    selectedIDs.removeAll { $0 == todo.id }
                    selectedTodos.removeAll { $0.id == todo.id }
                    print("  ❌ 선택 해제: \(todo.title)")
                } else {
                    if !selectedIDs.contains(todo.id) {
                        selectedIDs.append(todo.id)
                    }
                    if !selectedTodos.contains(where: { $0.id == todo.id }) {
                        selectedTodos.append(todo)
                    }
                    print("  ✅ 선택: \(todo.title)")
                }
            }
            // 자식이 있는 부모: 자식들만 토글
            else {
                let uncompletedChildren = todo.children.filter { !$0.isCompleted }
                let allChildrenSelected = uncompletedChildren.allSatisfy { isSelected($0.id) }
                
                if allChildrenSelected {
                    // 모든 자식 선택 해제
                    selectedIDs.removeAll { id in
                        uncompletedChildren.contains { $0.id == id }
                    }
                    selectedTodos.removeAll { selectedTodo in
                        uncompletedChildren.contains { $0.id == selectedTodo.id }
                    }
                    print("  ❌ 그룹 선택 해제: \(todo.title)")
                } else {
                    // 모든 미완료 자식 선택
                    for child in uncompletedChildren {
                        if !selectedIDs.contains(child.id) {
                            selectedIDs.append(child.id)
                        }
                        if !selectedTodos.contains(where: { $0.id == child.id }) {
                            selectedTodos.append(child)
                        }
                    }
                    print("  ✅ 그룹 선택: \(todo.title)")
                }
            }
        } else {
            // 자식 할 일인 경우
            toggleChildSelection(todo, !isSelected(todo))
        }
    }

    /// 선택 상태 초기화
    func clearSelections() {
        print("🧹 선택 상태 초기화")
        selectedTodos.removeAll()
        selectedIDs.removeAll()
        timeSettings.removeAll()
    }

    // MARK: - 부모 항목 선택/해제
    func toggleParentSelection(_ parent: Todo, _ select: Bool) {
        if parent.children.isEmpty {
            if select {
                if !selectedIDs.contains(parent.id) {
                    selectedIDs.append(parent.id)
                }
                if !selectedTodos.contains(where: { $0.id == parent.id }) {
                    selectedTodos.append(parent)
                }
            } else {
                selectedIDs.removeAll { $0 == parent.id }
                selectedTodos.removeAll { $0.id == parent.id }
            }
        } else {
            let uncompletedChildren = parent.children.filter { !$0.isCompleted }
            let ids = uncompletedChildren.map(\.id)
            
            if select {
                selectedIDs = Array(Set(selectedIDs + ids))
                for child in uncompletedChildren where !selectedTodos.contains(where: { $0.id == child.id }) {
                    selectedTodos.append(child)
                }
            } else {
                selectedIDs.removeAll { ids.contains($0) }
                selectedTodos.removeAll { ids.contains($0.id) }
            }
        }
    }

    // MARK: - 자식 항목 선택/해제
    func toggleChildSelection(_ child: Todo, _ select: Bool) {
        if child.isCompleted {
            print("⚠️ 완료된 자식 항목은 선택할 수 없습니다: \(child.title)")
            return
        }
        
        if select {
            if !selectedIDs.contains(child.id) { selectedIDs.append(child.id) }
            if !selectedTodos.contains(where: { $0.id == child.id }) { selectedTodos.append(child) }
            print("  ✅ 자식 선택: \(child.title)")
        } else {
            selectedIDs.removeAll { $0 == child.id }
            selectedTodos.removeAll { $0.id == child.id }
            print("  ❌ 자식 선택 해제: \(child.title)")
        }
    }

    // MARK: - 시간 설정
    func setTime(for todo: Todo) -> Int {
        timeSettings[todo.id] ?? todo.setTime
    }

    func updateSetTime(for todo: Todo, minutes: Int) {
        timeSettings[todo.id] = minutes
    }

    // MARK: - 선택된 항목 반환
    func pickedTodos(from parents: [Todo]) -> [Todo] {
        // ✅ 반환 전 완료된 항목 정리
        cleanupCompletedSelections()
        
        var result: [Todo] = []
        
        for parent in parents {
            if isSelected(parent.id) && parent.children.isEmpty {
                result.append(parent)
            } else {
                let selectedChildren = parent.children
                    .filter { !$0.isCompleted && isSelected($0.id) }
                result.append(contentsOf: selectedChildren)
            }
        }
        
        print("📦 pickedTodos: \(result.count)개 항목 선택됨")
        return result
    }

    // MARK: - 집중 모드 진입 준비
    func prepareFocusTarget() {
        selectedFocusTodos = pickedTodos(from: focusParents)
        print("🎯 집중 모드 준비 완료: \(selectedFocusTodos.count)개 할 일")
    }
    
    // MARK: - ✅ 완료된 항목 자동 정리
    private func cleanupCompletedSelections() {
        let beforeCount = selectedIDs.count
        
        // 완료된 Todo 제거
        selectedTodos.removeAll { $0.isCompleted }
        
        // 남아있는 Todo의 ID만 유지
        let validIDs = Set(selectedTodos.map { $0.id })
        selectedIDs = selectedIDs.filter { validIDs.contains($0) }
        
        let afterCount = selectedIDs.count
        if beforeCount != afterCount {
            print("🧹 완료된 항목 \(beforeCount - afterCount)개를 선택에서 제거")
        }
    }
}
