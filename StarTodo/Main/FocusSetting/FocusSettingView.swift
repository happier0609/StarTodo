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
    @State private var isNavigatingToTimer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                // ✅ 뷰모델에 실제로 존재하는 컬렉션 사용
                if focusSettingVM.focusParents.isEmpty {
                    VStack(spacing: 24) {
                        // 말풍선 안내
                        HStack {
                            Text("집중모드는 내가 당장 해야 할 일을\n‘진짜’ 실행할 수 있게 돕는 기능이에요.")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                                .padding(.leading, 32)
                            Spacer()
                        }
                        .padding(.top, 32)

                        // 캐릭터 일러스트
                        Image("Empty")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)

                        // 안내 문구
                        Text("완벽보다 중요한 건 시작하는 용기.\n지금 해낼 수 있는 일들을 선택해요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64)
                } else {
                    VStack(spacing: 16) {
                        // ✅ SwiftData 모델(Todo) 사용
                        ForEach(focusSettingVM.focusParents, id: \.id) { parent in
                            let children = parent.children
                            let selectedCount = children.filter { child in
                                focusSettingVM.isSelected(child.id)
                            }.count
                            
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
                                    focusSettingVM.toggleSelection(for: parent)
                                },
                                onChildTap: { child in
                                    focusSettingVM.toggleChild(child)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }

            // ✅ 선택수/액션도 뷰모델의 실제 이름으로 교체
            FocusStartButton(
                selectedCount: focusSettingVM.selectedIDs.count,
                action: {
                    // 선택된 항목을 뷰모델에서 꺼내기
                    let picked = focusSettingVM.pickedTodos(from: focusSettingVM.focusParents)
                    // MainVM에도 반영(필요 시)
                    mainVM.selectedIDs = picked.map(\.id)
                    isNavigatingToTimer = true
                }
            )
            .padding(.bottom, 24)

            NavigationLink(
                destination: TimerSettingView()
                    .environmentObject(mainVM),
                isActive: $isNavigatingToTimer
            ) { EmptyView() }
            .hidden()
        }
        .onAppear {
            // ✅ Start 탭에서 보여줄 "루트 Todo"만 전달
            focusSettingVM.loadFrom(mainVM.todoItems)
        }
    }
}

#Preview {
    MainView()
}
