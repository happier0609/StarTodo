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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AddListViewModel()
    
    // 타이머 추가 - 매분마다 UI 갱신을 위해
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mainContent
            VStack(spacing: -15) {
                Spacer()
                
                HStack {
                    Spacer()
                    addButton
                }
                resetInfoText
            }
        }
        .onAppear {
            print("📄 AddListView onAppear")
            refreshData()
        }
        // ✅ 앱 포그라운드 복귀
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("📄 AddListView ScenePhase Active")
                refreshData()
            }
        }
        // ✅ 매분마다 리셋 기준 시간 체크
        .onReceive(timer) { _ in
            print("⏰ AddListView 타이머 새로고침")
            refreshData()
        }
        // ✅ Todo 완료 상태 변경 감지 (FocusMode에서 완료 처리 시)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodoCompletionChanged"))) { notification in
            print("📄 AddListView TodoCompletionChanged 알림 수신")
            if let todoID = notification.userInfo?["todoID"] as? UUID {
                print("  변경된 Todo ID: \(todoID)")
            }
            if let isCompleted = notification.userInfo?["isCompleted"] as? Bool {
                print("  완료 여부: \(isCompleted)")
            }
            
            print("🔄 데이터 새로고침 시작...")
            refreshData()
        }
        .sheet(isPresented: $viewModel.showModal) {
            addTaskModalSheet
        }
        .alert("정말 삭제할까요?", isPresented: $viewModel.showAlert, presenting: viewModel.parentToDelete) { parent in
            deleteAlertButtons(for: parent)
        } message: { parent in
            deleteAlertMessage(for: parent)
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.parents.isEmpty {
            AddListEmptyView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    todaySection
                        .padding(.vertical, 8)
                    previousSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            }
        }
    }
    
    // MARK: - Today Section
    @ViewBuilder
    private var todaySection: some View {
        if !viewModel.todayParents.isEmpty {
            sectionHeader(title: "오늘 추가됨")
            TodoSectionView(
                todos: viewModel.todayParents,
                viewModel: viewModel
            )
        }
    }
    
    // MARK: - Previous Section
    @ViewBuilder
    private var previousSection: some View {
        if !viewModel.previousParents.isEmpty {
            sectionHeader(title: "이전에 추가됨")
            TodoSectionView(
                todos: viewModel.previousParents,
                viewModel: viewModel
            )
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .typo(.captionMDRegular)
            .foregroundColor(Color("Cool300"))
            .padding(.horizontal)
    }
    
    // MARK: - Reset Info Text
    private var resetInfoText: some View {
        Text("오늘 완료한 일은 매일 오전 5시에 리셋됩니다.")
            .typo(.captionMDRegular)
            .foregroundColor(Color("Cool300"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button {
            viewModel.editingParent = nil
            viewModel.showModal = true
        } label: {
            Image("addTodo")
                .padding()
        }
    }
    
    // MARK: - Add Task Modal Sheet
    private var addTaskModalSheet: some View {
        AddTaskModalView(
            isPresented: $viewModel.showModal,
            editingParent: viewModel.editingParent
        )
        .environmentObject(viewModel)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Delete Alert Buttons
    @ViewBuilder
    private func deleteAlertButtons(for parent: Todo) -> some View {
        Button("취소", role: .cancel) { }
        Button("삭제", role: .destructive) {
            viewModel.delete(parent: parent, in: context)
        }
    }
    
    // MARK: - Delete Alert Message
    private func deleteAlertMessage(for parent: Todo) -> some View {
        Text("\"\(parent.title)\"의 하위 항목 \(parent.children.count)개도 함께 삭제됩니다.")
    }
    
    // MARK: - Helper Methods
    private func refreshData() {
        print("🔄 AddListView 데이터 새로고침")
        print("  이전 부모 항목 수: \(viewModel.parents.count)")
        
        viewModel.fetchParents(with: context)
        
        print("  새로운 부모 항목 수: \(viewModel.parents.count)")
        print("  오늘 항목: \(viewModel.todayParents.count)개")
        print("  이전 항목: \(viewModel.previousParents.count)개")
    }
}

// MARK: - 프리뷰
#if DEBUG
import SwiftUI
import SwiftData

#Preview("AddListView - 기본 + 계층") {
    // 인메모리 SwiftData 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Todo.self,
        configurations: config
    )

    // 1. 기본 샘플 Todo
    let flatTodos = PreviewData.makeSampleTodos()
    for todo in flatTodos {
        container.mainContext.insert(todo)
    }

    // 2. 계층 구조 Todo (부모 + 자식)
    let hierarchicalTodos = PreviewData.makeTodosWithHierarchy()
    for todo in hierarchicalTodos {
        container.mainContext.insert(todo)
    }

    // AddListView와 연결
    return AddListView()
        .modelContainer(container)
        .environmentObject(MainCoordinator.shared)
        .previewDisplayName("할 일 목록 (기본 + 계층)")
        .previewLayout(.device)
        .previewDevice("iPhone 15 Pro")
}
#endif
