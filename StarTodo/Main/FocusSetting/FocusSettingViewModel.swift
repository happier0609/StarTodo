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

    // MARK: - 📌 선택된 할 일 목록
    
    /// 현재 선택된 할 일 전체 (Todo 객체 기준)
    @Published var selectedTodos: [Todo] = []
    
    /// 선택된 할 일의 ID만 저장 (중복 방지 및 빠른 체크용)
    @Published var selectedIDs: [UUID] = []

    
    // MARK: - ⏱ 시간 설정 캐시 (할 일 ID : 분 단위)
    
    /// 사용자가 설정한 시간값을 임시 저장하는 캐시
    @Published var timeSettings: [UUID: Int] = [:]

    
    // MARK: - ✅ 집중 모드 진입용 데이터
    
    /// 집중 모드에 진입할 때 사용할 최종 할 일 목록
    @Published var selectedFocusTodos: [Todo] = []

    
    // MARK: - 📁 부모 할 일 목록 (AddListViewModel 패턴 적용)
    
    /// UI에서 표시할 "상위 할 일" 목록 (자식 포함) - 수동 관리
    @Published var focusParents: [Todo] = []
    
    // MARK: - 🔄 확장/접기 상태 관리
    @Published var expandedParentIDs: Set<UUID> = []
    
    /// 특정 부모가 확장되어 있는지 확인
    func isExpanded(_ parent: Todo) -> Bool {
        expandedParentIDs.contains(parent.id)
    }
    
    /// 부모의 확장/접기 상태 토글
    func toggleExpanded(for parent: Todo) {
        if expandedParentIDs.contains(parent.id) {
            expandedParentIDs.remove(parent.id)
        } else {
            expandedParentIDs.insert(parent.id)
        }
    }

    
    // MARK: - 🔄 MainViewModel로부터 할 일 받아오기

    /// MainViewModel에서 전달된 할 일 중, 완료되지 않은 상위 항목만 저장
    func loadFrom(_ todos: [Todo]) {
        focusParents = todos.filter { $0.parent == nil && !$0.isCompleted }
    }
    
    // MARK: - ✨ 완료되지 않은 할 일 불러오기 (AddListViewModel 패턴 적용)
    func fetchUncompletedParents(with context: ModelContext) {
        do {
            // ✅ 완료되지 않은 부모 항목만 가져오기
            let descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { todo in
                    todo.parent == nil && !todo.isCompleted
                }
            )
            let fetchedTodos = try context.fetch(descriptor)
            
            // ✅ 수동으로 정렬 적용
            // 부모가 미완료면 자식 상태와 관계없이 모두 표시
            focusParents = fetchedTodos.sorted { a, b in
                if a.order != b.order {
                    return a.order < b.order
                }
                return a.createdAt < b.createdAt
            }
            
            print("✅ FocusSettingViewModel: \(focusParents.count)개의 미완료 부모 할 일을 불러왔습니다.")
            
            // 디버깅
            for parent in focusParents {
                let childCount = parent.children.count
                let uncompletedChildCount = parent.children.filter { !$0.isCompleted }.count
                
                if childCount == 0 {
                    print("  - \(parent.title) (단일 항목)")
                } else if uncompletedChildCount == 0 {
                    print("  - \(parent.title) (자식 모두 완료 → 부모만 표시)")
                } else {
                    print("  - \(parent.title) (미완료 자식: \(uncompletedChildCount)/\(childCount)개)")
                }
            }
            
            cleanupCompletedSelections()
            
        } catch {
            print("❌ FocusSettingViewModel fetch 실패: \(error.localizedDescription)")
            focusParents = []
        }
    }
    
    /// 부모 카드 확장 상태 초기화 (모두 접힘)
    func resetExpansionStates() {
        expandedParentIDs.removeAll()
    }

    // MARK: - ✨ 완료된 항목 선택 상태 정리 (개선)
    private func cleanupCompletedSelections() {
        let beforeCount = selectedIDs.count
        
        // 1. 완료된 Todo 제거
        selectedTodos.removeAll { todo in
            todo.isCompleted
        }
        
        // 2. 남아있는 Todo의 ID만 유지
        let validIDs = Set(selectedTodos.map { $0.id })
        selectedIDs = selectedIDs.filter { validIDs.contains($0) }
        
        let afterCount = selectedIDs.count
        if beforeCount != afterCount {
            print("🧹 완료된 항목 \(beforeCount - afterCount)개를 선택에서 제거했습니다.")
        }
    }
    
    // MARK: - ✅ 선택 여부 확인

    /// 특정 할 일(Todo 객체)이 선택되었는지 확인
    func isSelected(_ todo: Todo) -> Bool {
        selectedIDs.contains(todo.id)
    }

    /// 특정 ID(UUID)가 선택되었는지 확인 (뷰 코드 편의를 위해 오버로드)
    func isSelected(_ id: UUID) -> Bool {
        selectedIDs.contains(id)
    }

    
    // MARK: - 🔁 선택/해제 토글

    /// 할 일을 선택하거나 해제하는 함수 (부모는 자식과 함께 처리)
    func toggleSelection(of todo: Todo) {
        // ✨ 완료된 항목은 선택 불가
        if todo.isCompleted {
            print("⚠️ 완료된 항목은 선택할 수 없습니다: \(todo.title)")
            return
        }
        
        if todo.parent == nil {
            let isCurrentlySelected = isSelected(todo)
            
            // ✨ 자식이 없는 부모의 경우: 부모만 토글
            if todo.children.isEmpty {
                if isCurrentlySelected {
                    // 부모 선택 해제
                    selectedIDs.removeAll { $0 == todo.id }
                    selectedTodos.removeAll { $0.id == todo.id }
                } else {
                    // 부모 선택
                    if !selectedIDs.contains(todo.id) {
                        selectedIDs.append(todo.id)
                    }
                    if !selectedTodos.contains(where: { $0.id == todo.id }) {
                        selectedTodos.append(todo)
                    }
                }
            }
            // ✨ 자식이 있는 부모의 경우: 자식들만 토글
            else {
                let uncompletedChildren = todo.children.filter { !$0.isCompleted }
                
                // 모든 미완료 자식이 선택되어 있는지 확인
                let allChildrenSelected = uncompletedChildren.allSatisfy { isSelected($0.id) }
                
                if allChildrenSelected {
                    // 모든 자식 선택 해제
                    selectedIDs.removeAll { id in
                        uncompletedChildren.contains { $0.id == id }
                    }
                    selectedTodos.removeAll { selectedTodo in
                        uncompletedChildren.contains { $0.id == selectedTodo.id }
                    }
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
                }
            }
        } else {
            // 자식 할 일인 경우: 개별 토글
            toggleChildSelection(todo, !isSelected(todo))
        }
    }

    /// 선택 상태를 모두 초기화
    func clearSelections() {
        selectedTodos.removeAll()
        selectedIDs.removeAll()
        timeSettings.removeAll() // 시간 설정도 초기화
    }

    
    // MARK: - 👪 부모 항목 선택/해제 (자식 포함)

    /// 부모 할 일을 선택하거나 해제할 때, 자식 항목도 함께 처리
    func toggleParentSelection(_ parent: Todo, _ select: Bool) {
        // ✨ 자식이 없는 부모는 자신만, 자식이 있으면 자식들만 처리
        if parent.children.isEmpty {
            // 자식이 없는 부모: 자신만 처리
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
            // 자식이 있는 부모: 완료되지 않은 자식들만 처리
            let uncompletedChildren = parent.children.filter { !$0.isCompleted }
            let ids = uncompletedChildren.map(\.id)
            
            if select {
                // 선택
                selectedIDs = Array(Set(selectedIDs + ids)) // 중복 방지
                for child in uncompletedChildren where !selectedTodos.contains(where: { $0.id == child.id }) {
                    selectedTodos.append(child)
                }
            } else {
                // 선택 해제
                selectedIDs.removeAll { ids.contains($0) }
                selectedTodos.removeAll { ids.contains($0.id) }
            }
        }
    }

    
    // MARK: - 👶 자식 항목 선택/해제

    /// 자식 할 일을 선택하거나 해제하는 함수
    func toggleChildSelection(_ child: Todo, _ select: Bool) {
        // ✨ 완료된 자식은 선택 불가
        if child.isCompleted {
            print("⚠️ 완료된 자식 항목은 선택할 수 없습니다: \(child.title)")
            return
        }
        
        if select {
            if !selectedIDs.contains(child.id) { selectedIDs.append(child.id) }
            if !selectedTodos.contains(where: { $0.id == child.id }) { selectedTodos.append(child) }
        } else {
            selectedIDs.removeAll { $0 == child.id }
            selectedTodos.removeAll { $0.id == child.id }
        }
    }

    
    // MARK: - ⏲️ 시간 설정

    /// 특정 할 일의 시간 설정값을 가져옴 (없으면 원래 값 반환)
    func setTime(for todo: Todo) -> Int {
        timeSettings[todo.id] ?? todo.setTime
    }

    /// 특정 할 일의 시간 설정값을 업데이트
    func updateSetTime(for todo: Todo, minutes: Int) {
        timeSettings[todo.id] = minutes
    }

    
    // MARK: - 🆕 선택된 항목 반환하는 함수

    /// ✅ 부모 항목들로부터 선택된 모든 할 일(부모+자식)을 모아 리턴하는 함수
    /// - 파라미터: 상위 할 일 목록 (focusParents)
    /// - 리턴: 선택된 할 일들의 배열 (부모와 자식 모두 포함)
    func pickedTodos(from parents: [Todo]) -> [Todo] {
        var result: [Todo] = []
        
        for parent in parents {
            // 1. 부모가 선택되었고 자식이 없는 경우: 부모만 추가
            if isSelected(parent.id) && parent.children.isEmpty {
                result.append(parent)
            }
            // 2. 자식이 있는 경우: 선택된 자식들만 추가
            else {
                let selectedChildren = parent.children
                    .filter { !$0.isCompleted && isSelected($0.id) }
                result.append(contentsOf: selectedChildren)
            }
        }
        
        return result
    }

    
    // MARK: - 🚀 집중 모드 진입 준비

    /// ✅ 위의 pickedTodos() 함수를 활용해 집중 모드 대상 할 일들을 설정
    func prepareFocusTarget() {
        selectedFocusTodos = pickedTodos(from: focusParents)
    }
}
