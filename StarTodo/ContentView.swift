//
//  ContentView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 3/12/25.
//

import SwiftUI

enum TabBarType: Int, CaseIterable, Identifiable {
    case main, history

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .main: return "목록"
        case .history: return "히스토리"
        }
    }

    var selectedImageName: String {
        switch self {
        case .main: return "Star"
        case .history: return "My"
        }
    }

    var unselectedImageName: String {
        switch self {
        case .main: return "NullStar"
        case .history: return "NullMy"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .main: MainView()
        case .history: HistoryView()
        }
    }
}


struct ContentView: View {
    @State private var selectedTab: TabBarType = .main

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ForEach(TabBarType.allCases) { tab in
                    tab.view
                        .tabItem {
                            Image(selectedTab == tab ? tab.selectedImageName : tab.unselectedImageName)
                            Text(tab.title)
                        }
                        .tag(tab)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
