//
//  ContentView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 3/12/25.
//

import SwiftUI
import SwiftData

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
    func view(appCoordinator: AppCoordinator) -> some View {
        switch self {
        case .main:
            MainView()
                .environmentObject(appCoordinator.mainCoordinator)

        case .history:
            HistoryView()
        }
    }
}

struct ContentView: View {
    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $appCoordinator.selectedTab) {
            ForEach(TabBarType.allCases) { tab in
                NavigationStack(path: binding(for: tab)) {
                    tab.view(appCoordinator: appCoordinator)
                        .navigationDestination(for: MainScreen.self) { screen in
                            switch screen {
                            case .focusSetting:
                                FocusSettingView()
                            case .timerSetting(let ids):
                                TimerSettingView(todoIDs: ids)
                            case .focusMode(let ids):
                                FocusModeView(todoIDs: ids)
                            case .report(let sessionID):
                                ReportView(sessionID: sessionID)
                            }
                        }
                }
                .tabItem {
                    Image(appCoordinator.selectedTab == tab ? tab.selectedImageName : tab.unselectedImageName)
                    Text(tab.title)
                }
                .tag(tab)
            }
        }
    }

    // 탭에 따라 해당 코디네이터의 path를 바인딩
    func binding(for tab: TabBarType) -> Binding<NavigationPath> {
        switch tab {
        case .main:
            return $appCoordinator.mainCoordinator.path
        case .history:
            return $appCoordinator.historyCoordinator.path
        }
    }
}
