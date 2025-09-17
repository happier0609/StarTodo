//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI
import SwiftData

struct FocusModeView: View {
    // 외부에서 주입되는 Coordinator (탭 이동 등 앱 전체 흐름 제어용)
    @EnvironmentObject var coordinator: MainCoordinator

    // FocusModeView 전용 ViewModel. @StateObject로 소유권을 가짐 (한 번만 초기화됨)
    @StateObject private var viewModel: FocusModeViewModel

    // 탭 선택 상태 (타이머 탭 / 목록 탭)
    @State private var selectedTab: FocusTab = .timer

    // ✅ 커스텀 init 생성자 (외부에서 FocusTodoInput과 context를 받아 ViewModel 초기화)
    init(input: FocusTodoInput, context: ModelContext? = nil) {
        
        // context가 전달되지 않으면 defaultContext 사용 (환경에서 못 가져올 수도 있으므로)
        let ctx = context ?? defaultContext

        // ✅ @StateObject는 생성자에서 직접 접근 불가 → _viewModel(wrappedValue:)로 초기화해야 함!
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(
            todoIDPairs: input.todoIDPairs, // Focus할 할 일 목록
            context: ctx,                   // SwiftData 컨텍스트 (ModelContext)
            store: SwiftDataSessionStore(context: ctx) // 커스텀 세션 저장소
        ))
    }
    
    var body: some View {
        ZStack {
            // 전체 배경
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
        .onChange(of: viewModel.savedSession, perform: { (session: FocusSession?) in
            if let session {
                coordinator.push(.report(sessionID: session.id))
            }
        })
        
        .onAppear {
            viewModel.replaceStoreWithContext()
        }
    }
}

#Preview {
    let context = try! ModelContainer(for: FocusSession.self).mainContext
    let input = FocusTodoInput(todoIDPairs: [
        (UUID(), 1500), (UUID(), 900)
    ])
    return FocusModeView(input: input, context: context)
        .environmentObject(MainCoordinator.preview())
}
