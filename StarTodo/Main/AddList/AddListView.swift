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
    @EnvironmentObject var mainVM: MainViewModel
    
    // ✅ MainViewModel을 참조하는 ViewModel 생성
    @StateObject private var viewModel: AddListViewModel
    
    // ✅ 수정: mainViewModel을 optional로 전달
    init() {
        _viewModel = StateObject(wrappedValue: AddListViewModel(
            context: defaultContext,
            mainViewModel: nil  // ✅ optional이므로 nil 가능
        ))
    }
    
    // ✅ 스마트 타이머: 리셋 시간 1시간 전부터만 동작
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var isNearResetTime = false

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
        // ✅ onAppear에서 MainViewModel 연결만 수행
        .onAppear {
            if viewModel.mainViewModel == nil {
                viewModel.mainViewModel = mainVM
            }
            checkResetTime()
        }
        // ❌ scenePhase 제거 - MainView에서 처리
        // ❌ onAppear에서 refreshData() 제거 - MainViewModel이 자동으로 갱신
        // ❌ TodoCompletionChanged 제거 - @Published 구독으로 자동 갱신
        
        // ✅ 스마트 타이머: 리셋 시간 근처에만 UI 갱신
        .onReceive(timer) { _ in
            checkResetTime()
            if isNearResetTime {
                print("⏰ 리셋 시간 근처 - UI 갱신")
                // ✅ 수정: viewModel의 objectWillChange 사용
                viewModel.objectWillChange.send()
            }
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
    
    // MARK: - Helper: 리셋 시간 체크
    private func checkResetTime() {
        let now = Date()
        let calendar = Calendar.current
        
        var resetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        resetComponents.hour = mainVM.resetHour
        resetComponents.minute = 0
        
        guard let todayReset = calendar.date(from: resetComponents),
              let tomorrowReset = calendar.date(byAdding: .day, value: 1, to: todayReset) else {
            isNearResetTime = false
            return
        }
        
        // 현재 시간이 오늘 리셋 시간 1시간 전 ~ 내일 리셋 시간 1시간 후 사이인지 체크
        let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: todayReset)!
        let oneHourAfterTomorrow = calendar.date(byAdding: .hour, value: 1, to: tomorrowReset)!
        
        let wasNear = isNearResetTime
        isNearResetTime = (now >= oneHourBefore && now <= todayReset) ||
                          (now >= tomorrowReset && now <= oneHourAfterTomorrow)
        
        if isNearResetTime != wasNear {
            print("🔔 리셋 시간 근접 상태 변경: \(isNearResetTime)")
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
}

// MARK: - Preview
#if DEBUG
import SwiftUI
import SwiftData

#Preview("AddListView - 기본 + 계층") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Todo.self,
        configurations: config
    )

    let flatTodos = PreviewData.makeSampleTodos()
    for todo in flatTodos {
        container.mainContext.insert(todo)
    }

    let hierarchicalTodos = PreviewData.makeTodosWithHierarchy()
    for todo in hierarchicalTodos {
        container.mainContext.insert(todo)
    }

    return AddListView()
        .modelContainer(container)
        .environmentObject(MainCoordinator.shared)
        .environmentObject(MainViewModel(context: container.mainContext))
        .previewDisplayName("할 일 목록 (기본 + 계층)")
        .previewLayout(.device)
        .previewDevice("iPhone 15 Pro")
}
#endif
