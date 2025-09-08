//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI
import SwiftData

struct FocusModeView: View {
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: FocusTab = .timer
    
    var body: some View {
        ZStack {
            // ✅ 전체 배경
            Color("BgDark")
                .ignoresSafeArea()
            
            VStack {
                // 상단 종료 버튼 + 타이틀
                FocusModeHeaderView(
                    statusText: viewModel.headerStatusText,
                    viewModel: viewModel
                )
                
                NavigationLink(
                    destination: ReportView(
                        viewModel: ReportViewModel(), // 필요 시 데이터 전달
                        onComplete: {
                            // 메인 뷰로 돌아가기 등 처리
                        }
                    ),
                    isActive: $viewModel.shouldNavigateToReport
                ) {
                    EmptyView()
                }
                .hidden()
                
                // 세그먼티드 컨트롤
                CustomSegmentedControl(selectedTab: $selectedTab)
                    .padding()
                
                // 화면 전환
                switch selectedTab {
                case .timer:
                    FocusTimerView(viewModel: viewModel)
                case .list:
                    FocusListView(viewModel: viewModel)
                }
                
                FocusModeFooterView(
                    expectedEndTimeString: viewModel.expectedEndTimeString,
                    isBreakActive: viewModel.isBreakActive,
                    onRestTap: viewModel.endBreakAndResume
                )
            }
        }
        .breakTimeAlert(
            isPresented: Binding(
                get: { viewModel.showBreakSheet },
                set: { viewModel.showBreakSheet = $0 }
            ),
            minutes: Binding(
                get: { viewModel.breakPickedMinutes },
                set: { viewModel.breakPickedMinutes = $0 }
            ),
            onConfirm: {
                viewModel.startBreak()
            }
        )
        
        // ✅ 휴식 종료 오버레이
        .disabled(viewModel.showBreakEndOverlay) // 배경 인터랙션 잠금
        .overlay {
            if viewModel.showBreakEndOverlay {
                BreakEndOverlay {
                    viewModel.endBreakAndResume()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.replaceStoreWithContext()
        }
    }
}
