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
    @State private var todoIDPairs: [(UUID, Int)]
    
    // FocusTodoInput을 받아 ViewModel 초기화
    init(input: FocusTodoInput) {
        _todoIDPairs = State(initialValue: input.todoIDPairs)
        
        print("FocusModeView 초기화 시작")
        print("받은 데이터: \(input.todoIDPairs)")
        
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
            print("전달된 데이터: \(todoIDPairs)")
            
            // 환경에서 실제 ModelContext를 가져와서 ViewModel 업데이트
            updateViewModelContext()
            
            print("현재 로드된 할 일 개수: \(viewModel.todos.count)")
            for (index, todo) in viewModel.todos.enumerated() {
                let setMinutes = viewModel.todoTimeSettings[todo.id] ?? 0
                let timeText = setMinutes > 0 ? "\(setMinutes)분" : "시간 없음"
                print("  \(index): \(todo.title) - \(timeText)")
            }
        }
        // Back 버튼 숨기기, 잠금 상태 만들기
        .navigationBarBackButtonHidden(true)
        .focusLocked()
    }
    
    private func updateViewModelContext() {
        // 환경의 context를 ViewModel에 설정
        viewModel.modelContext = context
        viewModel.replaceStoreWithContext()
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
