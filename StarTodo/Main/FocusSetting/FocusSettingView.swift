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
                                // 미완료 자식만 필터링
                                let uncompletedChildren = parent.children
                                    .filter { !$0.isCompleted }
                                    .sorted(by: { $0.order < $1.order })

                                // 자식이 없는 단일 항목 또는 미완료 자식이 있는 그룹만 표시
                                if parent.children.isEmpty {
                                    FocusItemRowView(todo: parent, isChild: false)
                                        .onTapGesture {
                                            focusSettingVM.toggleSelection(of: parent)
                                        }
                                } else if !uncompletedChildren.isEmpty {
                                    let selectedCount = uncompletedChildren.filter {
                                        focusSettingVM.isSelected($0.id)
                                    }.count

                                    FocusGroupCardView(
                                        parent: parent,
                                        children: uncompletedChildren,
                                        isExpanded: focusSettingVM.isExpanded(parent),
                                        selectedChildCount: selectedCount,
                                        totalChildCount: uncompletedChildren.count,
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
        // ✅ onAppear에서 MainViewModel 연결만 수행
        .onAppear {
            if focusSettingVM.mainViewModel == nil {
                focusSettingVM.mainViewModel = mainVM
            }
        }
        // ❌ scenePhase 제거 - MainView에서 처리
        // ❌ onAppear에서 fetchUncompletedParents 제거 - MainViewModel이 자동으로 갱신
        // ❌ TodoCompletionChanged 제거 - @Published 구독으로 자동 갱신
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

@MainActor
private func makeFocusSettingPreview(using setup: (ModelContext) -> Void) -> some View {
    let container = createPreviewContainer()
    let context = container.mainContext
    
    setup(context)
    
    let mainVM = MainViewModel(context: context)
    mainVM.fetchTodos()
    
    let focusVM = FocusSettingViewModel()
    focusVM.mainViewModel = mainVM
    
    return FocusSettingView()
        .environmentObject(focusVM)
        .environmentObject(mainVM)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusSettingView - With Data") {
    makeFocusSettingPreview(using: setupMockData)
}

#Preview("FocusSettingView - Many Items") {
    makeFocusSettingPreview(using: setupManyItems)
}

#Preview("FocusSettingView - Empty State") {
    makeFocusSettingPreview(using: { _ in })
}
#endif
