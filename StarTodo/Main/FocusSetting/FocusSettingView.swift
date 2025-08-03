//
//  FocusSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import CoreData

struct FocusSettingView: View {
    @EnvironmentObject var focusSettingVM: FocusSettingViewModel
    @EnvironmentObject var mainVM: MainViewModel
    @State private var isNavigatingToTimer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if focusSettingVM.focusTodoGroups.isEmpty {
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
                        ForEach(mainVM.todoItems, id: \.id) { (parent: TodoEntity) in
                            let children = parent.childrenArray
                            let selectedCount = children.filter {
                                guard let id = $0.id else { return false }
                                return focusSettingVM.selectedTodoIDs.contains(id)
                            }.count
                            
                            FocusGroupCardView(
                                parent: parent,
                                children: children,
                                isExpanded: focusSettingVM.isExpanded(parent.id),
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
                                    focusSettingVM.toggleSelection(for: child)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            
            FocusStartButton(
                selectedCount: focusSettingVM.selectedTodoIDs.count,
                action: {
                    let selected = focusSettingVM.selectedTodos(from: mainVM.todoEntities)
                    mainVM.selectedIDs = selected.map { $0.wrappedID } // ✅ 이게 있어야 해!
                    isNavigatingToTimer = true
                }
            )
            .padding(.bottom, 24)
            
            NavigationLink(
                destination: TimerSettingView()
                    .environmentObject(mainVM),
                isActive: $isNavigatingToTimer
            ) {
                EmptyView()
            }
            .hidden()
        }
        
        // ✅ 여기 추가: Start 탭에서 할 일 목록을 불러오기
        .onAppear {
            focusSettingVM.loadUncompletedFrom(mainVM.todoEntities)
        }
    }
}

#Preview {
    MainView()
}
