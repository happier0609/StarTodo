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
            // 🔹 상단 탭바
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

            // 🔹 스와이프 가능한 탭 뷰
            TabView(selection: $selectedTab) {
                FocusSettingView()
                    .environmentObject(FocusSettingViewModel())
                    .environmentObject(mainVM)
                    .environmentObject(coordinator)
                    .tag(MainTabType.start)

                AddListView()
                    .tag(MainTabType.todo)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // 페이지 인디케이터 숨기기
        }
        .background(Color("BgLight"))
    }
}
