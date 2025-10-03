//
//  AddTaskModalViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 10/3/25.
//

import Foundation
import SwiftUI
import SwiftData

/// AddTaskModalView 전용 ViewModel
/// 할 일 추가/수정 모달의 비즈니스 로직을 담당
@MainActor
class AddTaskModalViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var title: String = ""
    @Published var children: [String] = [""]
    
    // MARK: - Properties
    private var editingParent: Todo?
    private weak var parentViewModel: AddListViewModel?
    private var context: ModelContext
    
    // MARK: - Computed Properties
    var isEditMode: Bool {
        editingParent != nil
    }
    
    var childrenCount: Int {
        children.filter { !$0.isEmpty }.count
    }
    
    var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var saveButtonTitle: String {
        isEditMode ? "수정 완료" : "추가하기"
    }
    
    var modalTitle: String {
        isEditMode ? "할 일 수정" : "새로운 할 일"
    }
    
    // MARK: - Initialization
    init(editingParent: Todo? = nil,
         parentViewModel: AddListViewModel,
         context: ModelContext) {
        self.editingParent = editingParent
        self.parentViewModel = parentViewModel
        self.context = context
        loadExistingData()
    }
    
    // MARK: - Setup
    func setupWithParent(_ parentVM: AddListViewModel, context: ModelContext) {
        self.parentViewModel = parentVM
        self.context = context
        loadExistingData()
    }
    
    // MARK: - Data Loading
    private func loadExistingData() {
        guard let todo = editingParent else { return }
        
        title = todo.title
        
        let existingChildren = todo.children
            .sorted(by: { $0.order < $1.order })
            .map { $0.title }
        
        if !existingChildren.isEmpty {
            children = existingChildren
        } else {
            children = [""]
        }
    }
    
    // MARK: - Child Management
    func addChild() {
        withAnimation(.easeInOut(duration: 0.2)) {
            children.append("")
        }
    }
    
    func removeChild(at index: Int) {
        // 최소 1개의 빈 필드는 유지
        if children.count > 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                children.remove(at: index)
            }
        } else if !children[index].isEmpty {
            children[index] = ""
        }
    }
    
    func canRemoveChild(at index: Int) -> Bool {
        children.count > 1 || !children[index].isEmpty
    }
    
    // MARK: - Save
    func save() {
        // 빈 문자열 필터링
        let filteredChildren = children.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        parentViewModel?.saveTodo(
            editingParent: editingParent,
            title: title,
            children: filteredChildren,
            context: context
        )
    }
}
