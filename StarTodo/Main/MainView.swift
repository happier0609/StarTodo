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
                    .environmentObject(mainVM.focusSettingViewModel) // ✅ mainVM의 인스턴스 사용
                    .environmentObject(mainVM)
                    .environmentObject(coordinator)
                    .tag(MainTabType.start)

                AddListView()
                    .tag(MainTabType.todo)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color("BgLight"))
        // ✅ selectedTab 변경 감지 - Start 탭으로 전환될 때마다 데이터 새로고침
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .start {
                print("📄 Start 탭 진입 - 데이터 새로고침")
                print("  이전 탭: \(oldValue.rawValue)")
                
                // 1. 데이터 새로고침
                mainVM.focusSettingViewModel.fetchUncompletedParents(with: context)
                
                // 2. 선택 초기화
                mainVM.focusSettingViewModel.clearSelections()
                
                // 3. 확장 상태 초기화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mainVM.focusSettingViewModel.resetExpansionStates()
                }
                
                print("  불러온 항목: \(mainVM.focusSettingViewModel.focusParents.count)개")
            }
        }
    }
}
