//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusModeView: View {
    let todoIDPairs: [(UUID, Int)]
    @StateObject private var viewModel: FocusModeViewModel
    
    @State private var selectedTab: Tab = .timer
    
    enum Tab {
        case timer, list
    }
    
    // ✅ 커스텀 생성자 추가
    init(todoIDPairs: [(UUID, Int)]) {
        self.todoIDPairs = todoIDPairs
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(todoIDPairs: todoIDPairs))
    }
    
    var body: some View {
        VStack {
            // 상단 종료 버튼 + 타이틀
            FocusModeHeaderView(
                elapsedMinutes: viewModel.elapsedTotalMinutes,
                onExit: {
                    viewModel.endFocusSession()
                }
            )
            NavigationLink(
                destination: ReportView(
                    viewModel: ReportViewModel(), // 새 인스턴스 또는 필요한 데이터를 전달
                    onComplete: {
                        // MainView로 돌아가기 위한 로직 (예: Navigation 상태 변경)
                    }
                ),
                isActive: $viewModel.shouldNavigateToReport
            ) {
                EmptyView()
            }
            .hidden()
            
            .padding()
            
            // 세그먼티드 컨트롤
            Picker("", selection: $selectedTab) {
                Text("타이머").tag(Tab.timer)
                Text("목록").tag(Tab.list)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 각 뷰 전환
            if selectedTab == .timer {
                FocusTimerView(viewModel: viewModel)
            } else {
                FocusListView(viewModel: viewModel)
            }
            
            FocusModeFooterView(
                expectedEndTimeString: viewModel.expectedEndTimeString,
                onRestTap: {
                    viewModel.showBreakSheet = true
                }
            )
        }
    }
}
