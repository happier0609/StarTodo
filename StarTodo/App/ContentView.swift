//
//  ContentView.swift
//  StarTodo
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
    
    // ✅ ModelContext와 MainViewModel을 직접 관리
    @Environment(\.modelContext) private var modelContext
    @StateObject private var mainViewModel: MainViewModel
    
    init() {
        // ✅ MainViewModel 초기화 - init에서는 임시 context 사용
        _mainViewModel = StateObject(wrappedValue: MainViewModel(context: defaultContext))
        
        // TabBar 스타일 설정
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
                    .environmentObject(mainCoordinator)
                    .environmentObject(mainViewModel)
                    .navigationDestination(for: MainScreen.self) { screen in
                        switch screen {
                        case .focusSetting:
                            FocusSettingView()
                                .environmentObject(mainCoordinator)
                                .environmentObject(mainViewModel)
                            
                        case .timerSetting(let selectedIDs, let allTodos):
                            TimerSettingView(selectedIDs: selectedIDs, allTodos: allTodos)
                                .environmentObject(mainCoordinator)
                                .environmentObject(mainViewModel)
                            
                        case .focusMode, .report:
                            // 🚫 fullScreenCover에서 처리하므로 여긴 무시
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Image(selectedTab == .main ? "Star" : "NullStar")
                Text("목록")
            }
            .tag(TabBarType.main)
            
            // ✅ History 탭
            HistoryView()
                .tabItem {
                    Image(selectedTab == .history ? "My" : "NullMy")
                    Text("히스토리")
                }
                .tag(TabBarType.history)
        }
        
        // ✅ FocusModeView / ReportView 전용 풀스크린 뷰
        .fullScreenCover(item: $mainCoordinator.fullScreenRoute) { screen in
            switch screen {
            case .focusMode(let input):
                FocusModeView(input: input)
                    .environment(\.modelContext, modelContext)
                    .focusLocked()
                
            case .report(let sessionID):
                // ✅ ReportView는 내부에서 ViewModel을 로드하므로 sessionID만 전달
                ReportView(sessionID: sessionID)
                    .environmentObject(mainCoordinator)
                    .environmentObject(mainViewModel)
                    .environment(\.modelContext, modelContext)
                    .focusLocked()
            }
        }
        // ✅ View가 나타날 때 실제 context로 업데이트
        .onAppear {
            #if DEBUG
            // 시연 영상용: -seedDemoData 실행 인자가 있을 때만 더미데이터 주입
            DemoDataSeeder.seedIfRequested(into: modelContext)
            #endif
            mainViewModel.updateContext(modelContext)
        }
    }
}
