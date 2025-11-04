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
    // REFRESH: ScenePhase 추가
    @Environment(\.scenePhase) private var scenePhase

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
        // REFRESH: MainView 최초 진입 시 데이터 로딩
        .onAppear {
            print("🟢 MainView onAppear")
            refreshAllData()
        }
        // REFRESH: 앱 포그라운드 복귀 시 갱신
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("🟢 MainView ScenePhase Active - 데이터 갱신")
                refreshAllData()
            }
        }
        // ✅ selectedTab 변경 감지 - Start 탭으로 전환될 때 선택 상태만 초기화
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .start {
                print("🔄 Start 탭 진입 (from \(oldValue.rawValue))")
                
                // ✅ 선택 초기화 (데이터는 FocusSettingView.onAppear에서 처리)
                mainVM.focusSettingViewModel.clearSelections()
                
                // ✅ 확장 상태 초기화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mainVM.focusSettingViewModel.resetExpansionStates()
                }
            }
        }
        // REFRESH: TodoCompletionChanged 노티피케이션 수신 (Report 복귀 시)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TodoCompletionChanged"))) { notification in
            print("🔔 MainView: TodoCompletionChanged 알림 수신")
            if let source = notification.userInfo?["source"] as? String {
                print("  소스: \(source)")
            }
            // Report 복귀 시 전체 갱신
            refreshAllData()
        }
    }
    
    // REFRESH: 전체 데이터 갱신 헬퍼 메서드
    private func refreshAllData() {
        print("🔄 MainView 전체 데이터 갱신")
        
        // 1. MainViewModel의 Todo 목록 갱신
        mainVM.refreshTodos()
        
        // 2. FocusSettingViewModel 데이터 갱신 (Start 탭인 경우에만)
        if selectedTab == .start {
            mainVM.focusSettingViewModel.fetchUncompletedParents(with: context)
        }
    }
}
