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
    @Published var children: [String] = []
    /// 하위 항목 최대 개수 초과 알림
    @Published var showChildLimitAlert = false
    /// 하위 항목은 최대 10개까지 (플로우 설계 기준)
    static let maxChildren = 10
    /// children와 같은 순서로, 기존 하위 할 일이면 그 id를 / 새로 추가한 칸이면 nil을 저장
    /// → 제목을 고쳐도 같은 할 일로 인식해 완료 상태와 집중 시간을 유지
    private var childIDs: [UUID?] = []
    
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
        
        children = existingChildren.map { $0.title }
        childIDs = existingChildren.map { Optional($0.id) }
    }
    
    // MARK: - Child Management
    func addChild() {
        guard children.count < Self.maxChildren else {
            showChildLimitAlert = true
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            children.append("")
            childIDs.append(nil)
        }
    }
    
    func removeChild(at index: Int) {
        // 최소 1개의 빈 필드는 유지
        if children.count > 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                children.remove(at: index)
                if childIDs.indices.contains(index) {
                    childIDs.remove(at: index)
                }
            }
        } else if !children[index].isEmpty {
            // 마지막 칸을 비우는 경우: 기존 하위 할 일과의 연결도 끊어 삭제되도록 함
            children[index] = ""
            if childIDs.indices.contains(index) {
                childIDs[index] = nil
            }
        }
    }
    
    func canRemoveChild(at index: Int) -> Bool {
        children.count > 1 || !children[index].isEmpty
    }
    
    // MARK: - Save
    func save() {
        // 제목과 id를 함께 넘기고, 빈 칸은 제외
        let drafts: [ChildDraft] = children.enumerated().compactMap { index, raw in
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let id = childIDs.indices.contains(index) ? childIDs[index] : nil
            return ChildDraft(id: id, title: trimmed)
        }
        
        parentViewModel?.saveTodo(
            editingParent: editingParent,
            title: title,
            children: drafts,
            context: context
        )
    }
}
