//
//  FocusSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import Foundation
import SwiftData

struct FocusSettingView: View {
    @EnvironmentObject var focusSettingVM: FocusSettingViewModel
    @EnvironmentObject var mainVM: MainViewModel
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if focusSettingVM.focusParents.isEmpty {
                FocusSettingEmptyView()
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("완벽보다 중요한건 시작하는 용기.")
                                    .typo(.textLGEmphasized)
                                    .foregroundColor(Color("Cool1100"))
                                Text("지금 해낼 수 있는 일들을 선택해요")
                                    .typo(.textLGEmphasized)
                                    .foregroundColor(Color("Cool1100"))
                            }
                            Spacer()
                        }
                        .padding(.leading, 18)
                        .padding(.vertical, 24)

                        VStack(spacing: 10) {
                            ForEach(focusSettingVM.focusParents) { parent in
                                let children = parent.children
                                    .filter { !$0.isCompleted }
                                    .sorted(by: { $0.order < $1.order })

                                if children.isEmpty {
                                    FocusItemRowView(todo: parent, isChild: false)
                                        .onTapGesture {
                                            focusSettingVM.toggleSelection(of: parent)
                                        }
                                } else {
                                    let selectedCount = children.filter { focusSettingVM.isSelected($0.id) }.count

                                    FocusGroupCardView(
                                        parent: parent,
                                        children: children,
                                        isExpanded: focusSettingVM.isExpanded(parent),
                                        selectedChildCount: selectedCount,
                                        totalChildCount: children.count,
                                        isSelected: focusSettingVM.isSelected(parent.id),
                                        onToggleExpand: {
                                            focusSettingVM.toggleExpanded(for: parent)
                                        },
                                        onParentTap: {
                                            focusSettingVM.toggleSelection(of: parent)
                                        },
                                        onChildTap: { child in
                                            focusSettingVM.toggleSelection(of: child)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    FocusStartButton(
                        selectedCount: focusSettingVM.selectedIDs.count,
                        action: {
                            let picked = focusSettingVM.pickedTodos(from: focusSettingVM.focusParents)
                            mainVM.selectedIDs = picked.map(\.id)

                            coordinator.push(.timerSetting(
                                selectedIDs: picked.map(\.id),
                                allTodos: picked
                            ))
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        // ✅ 최초 진입 시 (MainView의 onChange가 처리하지 못하는 첫 로드만)
        .onAppear {
            print("🔄 FocusSettingView onAppear")
            focusSettingVM.fetchUncompletedParents(with: context)
            focusSettingVM.clearSelections()
        }
        // ✅ 앱 포그라운드 복귀
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("🔄 FocusSettingView ScenePhase Active")
                focusSettingVM.fetchUncompletedParents(with: context)
            }
        }
        // ✅ 완료 상태 변경 감지
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodoCompletionChanged"))) { _ in
            print("🔄 FocusSettingView TodoCompletionChanged")
            focusSettingVM.fetchUncompletedParents(with: context)
        }
    }
}

// MARK: - Preview Helper
#if DEBUG
import SwiftUI
import SwiftData

@MainActor
private func createPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Todo.self, configurations: config) else {
        fatalError("⚠️ Failed to create preview container")
    }
    return container
}

@MainActor
private func setupMockData(context: ModelContext) {
    let parent1 = Todo(title: "운동하기", setTime: 30, order: 0)
    context.insert(parent1)
    
    let parent2 = Todo(title: "프로젝트 작업", setTime: 60, order: 1)
    let child2_1 = Todo(title: "UI 디자인 완성하기", setTime: 30, order: 0, parent: parent2)
    let child2_2 = Todo(title: "API 연동하기", setTime: 45, order: 1, parent: parent2)
    let child2_3 = Todo(title: "테스트 코드 작성", setTime: 25, order: 2, parent: parent2)
    [parent2, child2_1, child2_2, child2_3].forEach { context.insert($0) }
    
    let parent3 = Todo(title: "독서하기", setTime: 40, order: 2)
    let child3_1 = Todo(title: "1장 읽기", setTime: 20, order: 0, parent: parent3)
    let child3_2 = Todo(title: "2장 읽기", setTime: 20, order: 1, parent: parent3)
    [parent3, child3_1, child3_2].forEach { context.insert($0) }
    
    let parent4 = Todo(title: "완료된 할 일", setTime: 30, order: 3)
    parent4.isCompleted = true
    context.insert(parent4)
    
    try? context.save()
}

@MainActor
private func setupManyItems(context: ModelContext) {
    for i in 0..<5 {
        let parent = Todo(title: "할 일 그룹 \(i + 1)", setTime: 60, order: i)
        context.insert(parent)
        
        for j in 0..<3 {
            let child = Todo(
                title: "세부 작업 \(j + 1)",
                setTime: 20,
                order: j,
                parent: parent
            )
            context.insert(child)
        }
    }
    try? context.save()
}

// MARK: - ViewBuilder Helper

@MainActor
private func makeFocusSettingPreview(using setup: (ModelContext) -> Void) -> some View {
    let container = createPreviewContainer()
    let context = container.mainContext
    
    setup(context)
    
    let mainVM = MainViewModel(context: context)
    mainVM.fetchTodos()
    
    let focusVM = FocusSettingViewModel()
    focusVM.fetchUncompletedParents(with: context)
    
    return FocusSettingView()
        .environmentObject(focusVM)
        .environmentObject(mainVM)
        .modelContainer(container)
}

// MARK: - Preview
#Preview("FocusSettingView - With Data") {
    makeFocusSettingPreview(using: setupMockData)
}

#Preview("FocusSettingView - Many Items") {
    makeFocusSettingPreview(using: setupManyItems)
}

#Preview("FocusSettingView - Empty State") {
    makeFocusSettingPreview(using: { _ in })  // 데이터 없이 초기화
}
#endif
