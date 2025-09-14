//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: FocusTab = .timer
    
    // 커스텀 생성자에서 ViewModel 주입
    init(input: FocusTodoInput, context: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: FocusModeViewModel(
                todoIDPairs: input.todoIDPairs,
                context: context,
                store: SwiftDataSessionStore(context: context)
            )
        )
    }
    
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
        
        // ✅ 세션이 완료되었을 때 Coordinator로 이동
        .onChange(of: viewModel.savedSession) { session in
            if let session {
                coordinator.push(.report(sessionID: session.id))
            }
        }
        
        .onAppear {
            viewModel.replaceStoreWithContext()
        }
    }
}
