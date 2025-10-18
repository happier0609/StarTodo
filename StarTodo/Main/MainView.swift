//
//  MainView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import Foundation
import SwiftUI

enum MainTabType: String, CaseIterable {
    case start = "Start"
    case todo = "Todo"
}

struct MainView: View {
    @State private var selectedTab: MainTabType = .todo
    @EnvironmentObject var mainVM: MainViewModel
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 0) {
            // 📹 상단 탭바
            HStack {
                ForEach(MainTabType.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack {
                            Text(tab.rawValue)
                                .typo(tab == selectedTab ? .spartanBold : .spartanLight)
                                .foregroundColor(tab == selectedTab ? Color("Cool1100") : .gray)
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(tab == selectedTab ? .black : .clear)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
            .background(Color("App.White"))

            // 📹 스와이프 가능한 탭 뷰
            TabView(selection: $selectedTab) {
                FocusSettingView()
                    .environmentObject(mainVM.focusSettingViewModel)
                    .environmentObject(mainVM)
                    .environmentObject(coordinator)
                    .tag(MainTabType.start)

                AddListView()
                    .tag(MainTabType.todo)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color("BgLight"))
        // ✅ selectedTab 변경 감지 - Start 탭으로 전환될 때 선택 상태만 초기화
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .start {
                print("📄 Start 탭 진입 (from \(oldValue.rawValue))")
                
                // ✅ 선택 초기화 (데이터는 FocusSettingView.onAppear에서 처리)
                mainVM.focusSettingViewModel.clearSelections()
                
                // ✅ 확장 상태 초기화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mainVM.focusSettingViewModel.resetExpansionStates()
                }
            }
        }
    }
}
