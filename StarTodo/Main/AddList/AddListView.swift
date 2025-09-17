//
//  AddListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import SwiftData

struct AddListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = AddListViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if viewModel.parents.isEmpty {
                AddListEmptyView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !viewModel.todayParents.isEmpty {
                            Text("오늘 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)

                            todoSection(for: viewModel.todayParents)
                        }

                        if !viewModel.previousParents.isEmpty {
                            Text("이전에 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)

                            todoSection(for: viewModel.previousParents)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                }

                // 하단 리셋 문구
                Text("오늘 완료한 일은 매일 오전 5시에 리셋됩니다.")
                    .typo(.captionMDRegular)
                    .foregroundColor(Color("Cool300"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 80)
            }

            addButton
        }
        .sheet(isPresented: $viewModel.showModal) {
            AddTaskModalView(
                isPresented: $viewModel.showModal,
                editingParent: viewModel.editingParent
            )
            .environmentObject(viewModel)
            .presentationDetents([.medium, .large]) // 핵심! 모달 높이 설정
            .presentationDragIndicator(.visible)    // 위쪽 드래그 표시
        }
        .alert("정말 삭제할까요?", isPresented: $viewModel.showAlert, presenting: viewModel.parentToDelete) { parent in
            Button("삭제", role: .destructive) {
                viewModel.delete(parent: parent, in: context)
            }
            Button("취소", role: .cancel) { }
        } message: { parent in
            Text("\"\(parent.title)\"과 관련된 모든 할 일이 함께 삭제됩니다.")
        }
    }

    private var addButton: some View {
        Button {
            viewModel.editingParent = nil
            viewModel.showModal = true
        } label: {
            Image("addTodo")
                .padding()
        }
    }

    @ViewBuilder
    private func todoSection(for list: [Todo]) -> some View {
        VStack(spacing: 16) {
            ForEach(list) { parent in
                TodoGroupCardView(
                    parent: parent,
                    children: parent.children.sorted(by: { $0.order < $1.order }),
                    onToggle: { todo in
                        try? context.save()
                    },
                    onLongPressEdit: { _ in
                        viewModel.editingParent = parent
                        viewModel.showModal = true
                    }
                )
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if parent.children.isEmpty {
                            viewModel.delete(parent: parent, in: context)
                        } else {
                            viewModel.showDeleteAlert(for: parent)
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
    AddListView()
        .environmentObject(MainCoordinator.preview())
}
