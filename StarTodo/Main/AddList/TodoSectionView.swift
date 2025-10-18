//
//  TodoSectionView.swift
//  StarTodo
//
//  Created by 조민경 on 10/1/25.
//

import SwiftUI
import SwiftData

/// Todo 목록의 한 섹션을 표시하는 뷰
/// 오늘/이전 섹션에서 재사용됨
struct TodoSectionView: View {
    let todos: [Todo]
    let viewModel: AddListViewModel
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(todos) { parent in
                todoCard(for: parent)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func todoCard(for parent: Todo) -> some View {
        let visibleChildren = viewModel.getVisibleChildren(of: parent)
        
        SwipeableCardContainer(
            onDelete: {
                handleDelete(parent: parent)
            }
        ) {
            TodoGroupCardView(
                parent: parent,
                children: visibleChildren.sorted(by: { $0.order < $1.order }),
                onToggle: { todo in
                    // ✅ ViewModel로 위임
                    viewModel.toggleTodoCompletion(todo, context: context)
                },
                onLongPressEdit: { _ in
                    handleEdit(parent: parent)
                }
            )
        }
    }
    
    // MARK: - Action Handlers
    private func handleDelete(parent: Todo) {
        // 자식이 있으면 알럿 표시, 없으면 바로 삭제
        if !parent.children.isEmpty {
            viewModel.showDeleteAlert(for: parent)
        } else {
            viewModel.delete(parent: parent, in: context)
        }
    }
    
    private func handleEdit(parent: Todo) {
        viewModel.editingParent = parent
        viewModel.showModal = true
    }
    
    private func handleToggle(todo: Todo) {
        // ✅ ViewModel로 위임
        viewModel.toggleTodoCompletion(todo, context: context)
    }
}
