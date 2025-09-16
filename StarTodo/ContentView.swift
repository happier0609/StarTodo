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
}

struct ContentView: View {
    @State private var selectedTab: TabBarType = .main
    @ObservedObject private var mainCoordinator = MainCoordinator.shared
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ✅ Main 탭: NavigationStack + Coordinator 적용
            NavigationStack(path: $mainCoordinator.path) {
                MainView()
                    .environmentObject(MainCoordinator.shared)
                    .navigationDestination(for: MainScreen.self) { screen in
                        switch screen {
                        case .focusSetting:
                            FocusSettingView()
                                .environmentObject(mainCoordinator)
                            
                        case .timerSetting(let selectedIDs, let allTodos):
                            TimerSettingView(selectedIDs: selectedIDs, allTodos: allTodos)
                                .environmentObject(mainCoordinator)
                            
                        case .focusMode(let input):
                            FocusModeView(input: input)
                                .environmentObject(mainCoordinator)
                            
                        case .report(let sessionID):
                            let vm = ReportViewModel(sessionID: sessionID)
                            ReportView(
                                viewModel: vm,
                                onComplete: {
                                    mainCoordinator.popToRoot()
                                }
                            )
                            .environmentObject(mainCoordinator)
                        }
                    }
            }
            .tabItem {
                Image(selectedTab == .main ? "Star" : "NullStar")
                Text("목록")
            }
            .tag(TabBarType.main)
            
            // ❌ History 탭: 기존 방식 유지
            HistoryView()
                .tabItem {
                    Image(selectedTab == .history ? "My" : "NullMy")
                    Text("히스토리")
                }
                .tag(TabBarType.history)
        }
    }
}
