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
    @StateObject private var viewModel = MainViewModel() // 앱 전체에서 공유되는 단일 인스턴스
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 탭바
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
            .background(Color.white)
            
            // 탭에 따른 화면 전환
            switch selectedTab {
            case .start:
                FocusSettingView()
                    .environmentObject(FocusSettingViewModel()) // ✅ ViewModel 인스턴스 주입
                    .environmentObject(viewModel) // 이미 주입돼 있다면 생략 가능
            case .todo:
                AddListView(viewModel: viewModel)
            }
        }
        .background(Color("BgLight"))
    }
}

#Preview {
    ContentView()
}
