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
    @Environment(\.scenePhase) private var scenePhase // 앱 상태 감지
    
    var body: some View {
        ZStack {
            if focusSettingVM.focusParents.isEmpty {
                FocusSettingEmptyView()
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("완벽보다 중요한건 시작하는 용기")
                                .typo(.textLGEmphasized)
                                .foregroundColor(Color("Cool1100"))
                            Text("지금 해낼 수 있는 일들을 선택해요")
                                .typo(.textLGEmphasized)
                                .foregroundColor(Color("Cool1100"))
                        }
                        
                        VStack(spacing: 16) {
                            ForEach(focusSettingVM.focusParents) { parent in
                                let children = parent.children
                                    .filter { !$0.isCompleted } // ✨ 완료된 자식 제외
                                    .sorted(by: { $0.order < $1.order })
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
                    .frame(maxWidth: .infinity, alignment: .trailing) // ✅ 오른쪽 정렬
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        // ✨ 뷰가 나타날 때마다 데이터 로드
            .onAppear {
                print("🔄 FocusSettingView onAppear - 데이터 로딩 시작")
                focusSettingVM.fetchUncompletedParents(with: context)
                focusSettingVM.clearSelections() // 선택 상태 초기화
            }
        // ✨ ScenePhase 변경 감지 (백그라운드에서 돌아올 때)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    print("🔄 FocusSettingView ScenePhase Active - 데이터 갱신")
                    focusSettingVM.fetchUncompletedParents(with: context)
                }
            }
        // ✨ 네비게이션으로 돌아올 때 추가 감지
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                print("🔄 FocusSettingView didBecomeActive - 데이터 갱신")
                focusSettingVM.fetchUncompletedParents(with: context)
            }
        // ✨ Todo 완료 상태 변경 감지
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodoCompletionChanged"))) { _ in
                print("🔄 FocusSettingView TodoCompletionChanged - 데이터 갱신")
                focusSettingVM.fetchUncompletedParents(with: context)
            }
    }
}
