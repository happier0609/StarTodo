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

    
    // MARK: - 📁 부모 할 일 목록
    
    /// UI에서 표시할 "상위 할 일" 목록 (자식 포함)
    @Published var focusParents: [Todo] = []

    
    // MARK: - 🔄 MainViewModel로부터 할 일 받아오기

    /// MainViewModel에서 전달된 할 일 중, 완료되지 않은 상위 항목만 저장
    func loadFrom(_ todos: [Todo]) {
        focusParents = todos.filter { $0.parent == nil && !$0.isCompleted }
    }
    
    // MARK: - 완료되지 않은 할 일 불러오기
    func fetchUncompletedParents(with context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { todo in
                    todo.parent == nil && !todo.isCompleted
                }
            )

            let fetched = try context.fetch(descriptor)

            // 정렬 기준은 AddListViewModel과 동일
            let sorted = fetched.sorted { a, b in
                let left = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
                let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
                return left < right
            }

            // 예: published 속성으로 정의한 변수에 저장
            self.focusParents = sorted

        } catch {
            print("❌ FocusSettingViewModel fetch 실패: \(error.localizedDescription)")
            self.focusParents = []
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

    /// 할 일을 선택하거나 해제하는 함수
    func toggleSelection(of todo: Todo) {
        if isSelected(todo) {
            // 선택 해제
            selectedTodos.removeAll { $0.id == todo.id }
            selectedIDs.removeAll { $0 == todo.id }
        } else {
            // 선택 추가
            selectedTodos.append(todo)
            selectedIDs.append(todo.id)
        }
    }

    /// 선택 상태를 모두 초기화
    func clearSelections() {
        selectedTodos.removeAll()
        selectedIDs.removeAll()
    }

    
    // MARK: - 👪 부모 항목 선택/해제 (자식 포함)

    /// 부모 할 일을 선택하거나 해제할 때, 자식 항목도 함께 처리
    func toggleParentSelection(_ parent: Todo, _ select: Bool) {
        let ids = [parent.id] + parent.children.map(\.id)

        if select {
            // 선택
            selectedIDs = Array(Set(selectedIDs + ids)) // 중복 방지
            for t in [parent] + parent.children where !selectedTodos.contains(where: { $0.id == t.id }) {
                selectedTodos.append(t)
            }
        } else {
            // 선택 해제
            selectedIDs.removeAll { ids.contains($0) }
            selectedTodos.removeAll { ids.contains($0.id) }
        }
    }

    
    // MARK: - 👶 자식 항목 선택/해제

    /// 자식 할 일을 선택하거나 해제하는 함수
    func toggleChildSelection(_ child: Todo, _ select: Bool) {
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

    
    // MARK: - 🆕 선택된 자식 항목만 반환하는 함수

    /// ✅ 부모 항목들로부터 선택된 자식 할 일만 모아 리턴하는 함수
    /// - 파라미터: 상위 할 일 목록 (focusParents)
    /// - 리턴: 선택된 자식 할 일들의 배열
    func pickedTodos(from parents: [Todo]) -> [Todo] {
        parents.flatMap { parent in
            parent.children.filter { isSelected($0.id) }
        }
    }

    
    // MARK: - 🚀 집중 모드 진입 준비

    /// ✅ 위의 pickedTodos() 함수를 활용해 집중 모드 대상 할 일들을 설정
    func prepareFocusTarget() {
        selectedFocusTodos = pickedTodos(from: focusParents)
    }
}
