//
//  MainView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//  Updated: 민감도 최적화 - 스크롤 우선, 탭 전환 쉽게
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
    @Environment(\.scenePhase) private var scenePhase
    
    // ✅ 제스처 상태 관리
    @State private var dragOffset: CGFloat = 0
    
    // ✅ 민감도 최적화 설정
    private let edgeThreshold: CGFloat = 50      // 40 → 50 (가장자리 범위 확대)
    private let swipeThreshold: CGFloat = 40     // 80 → 60 (탭 전환 더 쉽게)
    private let minimumDistance: CGFloat = 15    // 10 → 15 (우발적 감지 방지)
    private let edgeWidth: CGFloat = 28          // 터치 가능한 가장자리 폭 (24~36 사이 조절)
    private let velocityThreshold: CGFloat = 400 // 빠른 스와이프 전환용 임계치
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 탭바
                customTabBar
                
                // 컨텐츠 영역
                ZStack {
                    // Start 탭
                    FocusSettingView()
                        .environmentObject(mainVM.focusSettingViewModel)
                        .environmentObject(mainVM)
                        .environmentObject(coordinator)
                        .opacity(selectedTab == .start ? 1 : 0)
                        .offset(x: tabOffset(for: .start, screenWidth: geometry.size.width))
                        .zIndex(selectedTab == .start ? 1 : 0)
                    
                    // Todo 탭
                    AddListView()
                        .opacity(selectedTab == .todo ? 1 : 0)
                        .offset(x: tabOffset(for: .todo, screenWidth: geometry.size.width))
                        .zIndex(selectedTab == .todo ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: edgeWidth)
                        .contentShape(Rectangle())      // 투명 터치 영역
                        .highPriorityGesture(           // 가장자리 제스처 우선
                            DragGesture(minimumDistance: 15, coordinateSpace: .global)
                                .onChanged { value in
                                    // 왼쪽 에지 → 오른쪽으로 스와이프일 때만 미리보기 허용 (Todo → Start)
                                    let t = value.translation.width
                                    guard selectedTab == .todo, t > 0 else {
                                        dragOffset = 0
                                        return
                                    }
                                    dragOffset = t * 0.5  // 살짝 저항감
                                }
                                .onEnded { value in
                                    let t = value.translation.width
                                    let v = value.predictedEndTranslation.width
                                    let shouldSwitch = (t > swipeThreshold) || (v > velocityThreshold)
                                    
                                    if selectedTab == .todo, shouldSwitch {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedTab = .start
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        print("➡️ Todo → Start 탭 전환")
                                    }
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                }
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: edgeWidth)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 15, coordinateSpace: .global)
                                .onChanged { value in
                                    // 오른쪽 에지 → 왼쪽으로 스와이프일 때만 미리보기 허용 (Start → Todo)
                                    let t = value.translation.width
                                    guard selectedTab == .start, t < 0 else {
                                        dragOffset = 0
                                        return
                                    }
                                    dragOffset = t * 0.5
                                }
                                .onEnded { value in
                                    let t = value.translation.width
                                    let v = value.predictedEndTranslation.width
                                    let shouldSwitch = (abs(t) > swipeThreshold) || (abs(v) > velocityThreshold)
                                    
                                    if selectedTab == .start, t < 0, shouldSwitch {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedTab = .todo
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        print("⬅️ Start → Todo 탭 전환")
                                    }
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                        )
                }
            }
            .background(Color("BgLight"))
        }
        .onAppear {
            print("🟢 MainView onAppear")
            mainVM.fetchTodos()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                print("🟢 MainView ScenePhase Active - 데이터 갱신")
                mainVM.refreshTodos()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .start {
                print("🔄 Start 탭 진입 (from \(oldValue.rawValue))")
                mainVM.focusSettingViewModel.clearSelections()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mainVM.focusSettingViewModel.resetExpansionStates()
                }
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack {
            ForEach(MainTabType.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
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
    }
    
    // MARK: - Tab Offset Calculation
    private func tabOffset(for tab: MainTabType, screenWidth: CGFloat) -> CGFloat {
        switch (selectedTab, tab) {
        case (.start, .start):
            return 0 + dragOffset
        case (.start, .todo):
            return screenWidth + dragOffset
        case (.todo, .start):
            return -screenWidth + dragOffset
        case (.todo, .todo):
            return 0 + dragOffset
        }
    }
}
