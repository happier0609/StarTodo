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
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: FocusTab = .timer

    // FocusTodoInput을 받아 ViewModel 초기화
    init(input: FocusTodoInput) {
        print("FocusModeView 초기화 시작")
        print("받은 데이터: \(input.todoIDPairs)")

        // 기본 컨텍스트로 임시 초기화 (onAppear에서 실제 컨텍스트로 교체)
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(
            todoIDPairs: input.todoIDPairs,
            context: defaultContext,
            store: SwiftDataSessionStore(context: defaultContext)
        ))
    }
    
    var body: some View {
        ZStack {
            Color("BgDark")
                .ignoresSafeArea()
            
            VStack {
                FocusModeHeaderView(
                    statusText: viewModel.headerStatusText,
                    viewModel: viewModel
                )
                
                CustomSegmentedControl(selectedTab: $selectedTab)
                    .padding()
                
                switch selectedTab {
                case .timer:
                    FocusTimerView(viewModel: viewModel)
                case .list:
                    FocusListView(viewModel: viewModel)
                }
                
                FocusModeFooterView(
                    expectedEndTimeString: viewModel.expectedEndTimeString,
                    isBreakActive: viewModel.isBreakActive,
                    onRestTap: {
                        if viewModel.isBreakActive {
                            viewModel.endBreakAndResume()
                        } else {
                            viewModel.showBreakSheet = true
                        }
                    }
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
        .disabled(viewModel.showBreakEndOverlay)
        .overlay {
            if viewModel.showBreakEndOverlay {
                BreakEndOverlay {
                    viewModel.endBreakAndResume()
                }
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.savedSession) {
            if let session = viewModel.savedSession {
                print("세션 완료 - ReportView로 이동: \(session.id)")
                coordinator.push(.report(sessionID: session.id))
            }
        }
        .onAppear {
            print("FocusModeView 나타남")
            
            // 환경에서 실제 ModelContext를 가져와서 ViewModel 업데이트
            updateViewModelContext()
            
            print("현재 로드된 할 일 개수: \(viewModel.todos.count)")
            for (index, todo) in viewModel.todos.enumerated() {
                let setMinutes = viewModel.todoTimeSettings[todo.id] ?? 0
                let timeText = setMinutes > 0 ? "\(setMinutes)분" : "시간 없음"
                print("  \(index): \(todo.title) - \(timeText)")
            }
        }
    }
    
    private func updateViewModelContext() {
        // 새로운 컨텍스트로 store 교체
        viewModel.replaceStoreWithContext()
        
        // 필요하다면 여기서 추가 초기화 작업 수행
    }
}

#Preview {
    let context = try! ModelContainer(for: FocusSession.self).mainContext
    let input = FocusTodoInput(todoIDPairs: [
        (UUID(), 25), (UUID(), 0) // 두 번째는 시간 없음
    ])
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.preview())
}
