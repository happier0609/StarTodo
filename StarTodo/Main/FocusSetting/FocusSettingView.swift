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
    
    @Environment(\.modelContext) private var context   // ✅ SwiftData ModelContext 주입
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if focusSettingVM.focusParents.isEmpty {
                    FocusSettingEmptyView()
                } else {
                    VStack(spacing: 16) {
                        ForEach(focusSettingVM.focusParents) { parent in
                            let children = parent.children.sorted(by: { $0.order < $1.order })
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
                    .padding(.horizontal)
                    .padding(.top)
                }
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
            .padding(.bottom, 24)
        }
        // ✨ 핵심: View가 나타날 때마다 데이터 fetch (AddListView 패턴 적용)
        .onAppear {
            print("🔄 FocusSettingView onAppear - 데이터 로딩 시작")
            focusSettingVM.fetchUncompletedParents(with: context)
        }
        // ✨ ScenePhase 변화 감지 (백그라운드에서 돌아올 때도 갱신)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("🔄 FocusSettingView willEnterForeground - 데이터 갱신")
            focusSettingVM.fetchUncompletedParents(with: context)
        }
        // ✨ 추가: Todo 완료 상태 변경을 감지하기 위한 알림 (선택사항)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodoCompletionChanged"))) { _ in
            print("🔄 FocusSettingView TodoCompletionChanged - 데이터 갱신")
            focusSettingVM.fetchUncompletedParents(with: context)
        }
    }
}

