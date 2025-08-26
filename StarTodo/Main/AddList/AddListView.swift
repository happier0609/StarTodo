//
//  AddListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI

struct AddListView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showModal = false
    @State private var editingTodo: TodoEntity? = nil
    @State private var showAlert = false
    @State private var todoToDelete: TodoEntity? = nil

    private func showDeleteAlert(for todo: TodoEntity) {
        todoToDelete = todo
        showAlert = true
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if viewModel.todayTodos.isEmpty && viewModel.previousTodos.isEmpty {
                // 👉 할 일 없을 때 EmptyView로 대체
                AddListEmptyView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !viewModel.todayTodos.isEmpty {
                            Text("오늘 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)

                            todoSection(for: viewModel.todoItems)
                        }

                        if !viewModel.previousTodos.isEmpty {
                            Text("이전에 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)

                            todoSection(for: viewModel.previousTodos)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                    Text("오늘 완료한 일은 매일 오전 5시에 리셋됩니다.")
                        .typo(.captionMDRegular)
                        .foregroundColor(Color("Cool300"))
                }
                .transition(.move(edge: .leading))
            }

            addButton
        }
        .sheet(isPresented: $showModal) {
            AddTaskModalView(isPresented: $showModal, editingTodo: $editingTodo)
                .environmentObject(viewModel)
        }
        .alert("정말 삭제할까요?", isPresented: $showAlert, presenting: todoToDelete) { todo in
            Button("삭제", role: .destructive) {
                viewModel.deleteTodo(todo)
            }
            Button("취소", role: .cancel) { }
        } message: { todo in
            Text("\"\(todo.wrappedTitle)\"과 관련된 모든 할 일이 함께 삭제됩니다.")
        }
    }

    private var addButton: some View {
        Button(action: {
            editingTodo = nil
            showModal = true
        }) {
            Image("addTodo")
                .padding()
        }
    }

    @ViewBuilder
    private func todoSection(for list: [TodoEntity]) -> some View {
        VStack(spacing: 16) {
            ForEach(list, id: \.objectID) { parent in
                TodoGroupCardView(
                    parent: parent,
                    children: parent.childrenArray,
                    onToggle: { todo in
                        viewModel.toggleTodo(todo)
                    },
                    onLongPressEdit: { todo in
                        editingTodo = todo
                        showModal = true
                    }
                )
                .background(Color.white)
                .contentShape(Rectangle()) // 터치 확장
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if parent.childrenArray.isEmpty {
                            viewModel.deleteTodo(parent)
                        } else {
                            showDeleteAlert(for: parent)
                        }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
