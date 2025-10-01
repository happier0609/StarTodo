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
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.delete(parent: parent, in: context)
            }
        } message: { parent in
            Text("\"\(parent.title)\"의 하위 항목 \(parent.children.count)개도 함께 삭제됩니다.")
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
                
                SwipeableCardContainer(
                    onDelete: {
                        // 자식이 있으면 알럿 표시, 없으면 바로 삭제
                        if !parent.children.isEmpty {
                            viewModel.showDeleteAlert(for: parent)
                        } else {
                            viewModel.delete(parent: parent, in: context)
                        }
                    }
                ) {
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
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Swipeable Card Container
struct SwipeableCardContainer<Content: View>: View {
    @State private var offset: CGFloat = 0
    @State private var isDeletingIconVisible = false
    
    let onDelete: () -> Void
    let content: Content
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 삭제 버튼 배경
            HStack {
                Spacer()
                
                Button(action: onDelete) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("삭제")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80)
                }
                .opacity(isDeletingIconVisible ? 1 : 0)
            }
            .frame(height: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red)
                    .opacity(isDeletingIconVisible ? 1 : 0)
            )
            
            // 실제 카드 콘텐츠
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 왼쪽으로만 스와이프 가능
                            if value.translation.width < 0 {
                                offset = value.translation.width
                                isDeletingIconVisible = offset < -50
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                // 충분히 스와이프했으면 삭제 버튼 표시
                                if value.translation.width < -100 {
                                    offset = -80
                                    isDeletingIconVisible = true
                                } else {
                                    // 원위치로 복귀
                                    offset = 0
                                    isDeletingIconVisible = false
                                }
                            }
                        }
                )
        }
    }
}
