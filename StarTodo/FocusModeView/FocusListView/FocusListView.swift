//
//  FocusListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusListView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        let enumeratedTodos = Array(viewModel.sortedTodosForListView.enumerated())

        return VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(enumeratedTodos, id: \.offset) { index, todo in
                        let isCurrent = todo.id == viewModel.currentTodo?.id
                        
                        FocusListRowView(
                            title: todo.title,
                            isCompleted: todo.isCompleted,
                            isCurrent: isCurrent,
                            onComplete: {
                                viewModel.markTodoAsCompleted(at: index)
                            }
                        )
                        .onTapGesture {
                            viewModel.selectTodo(at: index)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("Cool1000"))
                )
                .padding(.horizontal)
            }
        }
    }
}
