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
    
    // 타이머 추가 - 매분마다 UI 갱신을 위해
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

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
        // ✨ 핵심: View가 나타날 때마다 데이터 fetch
        .onAppear {
            viewModel.fetchParents(with: context)
        }
        // ✨ ScenePhase 변화 감지 (백그라운드에서 돌아올 때도 갱신)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.fetchParents(with: context)
        }
        // ✨ 매분마다 UI 갱신 (새벽 5시 자동 갱신용)
        .onReceive(timer) { _ in
            viewModel.fetchParents(with: context)
        }
        .sheet(isPresented: $viewModel.showModal) {
            AddTaskModalView(
                isPresented: $viewModel.showModal,
                editingParent: viewModel.editingParent
            )
            .environmentObject(viewModel)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                // ViewModel에서 표시 가능한 자식 가져오기
                let visibleChildren = viewModel.getVisibleChildren(of: parent)
                
                TodoGroupCardView(
                    parent: parent,
                    children: visibleChildren.sorted(by: { $0.order < $1.order }),
                    onToggle: { todo in
                        todo.isCompleted.toggle()
                        if todo.isCompleted {
                            todo.performedDate = Date()
                        } else {
                            todo.performedDate = nil
                        }
                        
                        do {
                            try context.save()
                            // ✨ 완료 상태 변경 시에도 목록 갱신
                            viewModel.fetchParents(with: context)
                        } catch {
                            print("❌ 완료 상태 저장 실패: \(error.localizedDescription)")
                        }
                    },
                    onLongPressEdit: { _ in
                        viewModel.editingParent = parent
                        viewModel.showModal = true
                    }
                )
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal)
    }
}
