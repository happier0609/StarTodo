//
//  FocusSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import Foundation

struct FocusSettingView: View {
    @EnvironmentObject var focusSettingVM: FocusSettingViewModel
    @EnvironmentObject var mainVM: MainViewModel
    @EnvironmentObject var coordinator: MainCoordinator
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                // ✅ 뷰모델에 실제로 존재하는 컬렉션 사용
                if focusSettingVM.focusParents.isEmpty {
                    FocusSettingEmptyView()
                } else {
                    VStack(spacing: 16) {
//                        // ✅ SwiftData 모델(Todo) 사용
//                        ForEach(focusSettingVM.focusParents, id: \.id) { parent in
//                            let children = parent.children
//                            let selectedCount = children.filter { child in
//                                focusSettingVM.isSelected(child.id)
//                            }.count
//                            
//                            FocusGroupCardView(
//                                parent: parent,
//                                children: children,
//                                isExpanded: focusSettingVM.isExpanded(parent),
//                                selectedChildCount: selectedCount,
//                                totalChildCount: children.count,
//                                isSelected: focusSettingVM.isSelected(parent.id),
//                                onToggleExpand: {
//                                    focusSettingVM.toggleExpanded(for: parent)
//                                },
//                                onParentTap: {
//                                    focusSettingVM.toggleSelection(for: parent)
//                                },
//                                onChildTap: { child in
//                                    focusSettingVM.toggleChild(child)
//                                }
//                            )
//                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }

            // TODO: 네비게이션, 라우터
            FocusStartButton(
                selectedCount: focusSettingVM.selectedIDs.count,
                action: {
                    let picked = focusSettingVM.pickedTodos(from: focusSettingVM.focusParents)
                    mainVM.selectedIDs = picked.map(\.id)

                    // ✅ coordinator로 화면 전환
                    coordinator.push(.timerSetting(
                        selectedIDs: picked.map(\.id),
                        allTodos: picked
                    ))
                }
            )
            .padding(.bottom, 24)
        }
        .onAppear {
//            // ✅ Start 탭에서 보여줄 "루트 Todo"만 전달
//            focusSettingVM.loadFrom(mainVM.todoItems)
        }
    }
}


#Preview {
    FocusSettingView()
        .environmentObject(MainCoordinator.preview())
}
