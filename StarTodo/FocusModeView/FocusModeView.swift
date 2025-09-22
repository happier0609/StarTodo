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

    /// FocusTodoInput을 받아 ViewModel을 초기화하는 생성자
    init(input: FocusTodoInput) {
        print("\n✅ FocusModeView 초기화 시작")
        print("받은 데이터: \(input.todoIDPairs)")

        // 기본 context로 임시 store를 생성 (onAppear에서 실제 context로 교체)
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(
            todoIDPairs: input.todoIDPairs,
            context: defaultContext, // placeholder
            store: SwiftDataSessionStore(context: defaultContext)
        ))
    }

    var body: some View {
        ZStack {
            Color("BgDark")
                .ignoresSafeArea()

            VStack {
                /// 상단 상태 텍스트 표시
                FocusModeHeaderView(
                    statusText: viewModel.headerStatusText,
                    viewModel: viewModel
                )

                /// 세그먼트 탭 (타이머 / 목록)
                CustomSegmentedControl(selectedTab: $selectedTab)
                    .padding()

                /// 탭에 따라 타이머 뷰 혹은 목록 뷰 표시
                switch selectedTab {
                case .timer:
                    FocusTimerView(viewModel: viewModel)
                case .list:
                    FocusListView(viewModel: viewModel)
                }

                /// 하단 버튼 영역 (휴식, 예상 종료 시간)
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
        // ✅ 휴식 시간 설정 시트
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
        .disabled(viewModel.showBreakEndOverlay)
        .overlay {
            if viewModel.showBreakEndOverlay {
                BreakEndOverlay {
                    viewModel.endBreakAndResume()
                }
                .transition(.opacity)
            }
        }
        // ✅ 세션이 완료되면 ReportView로 이동
        .onChange(of: viewModel.savedSession) {
            if let session = viewModel.savedSession {
                print("\n✅ 세션 완료 - ReportView로 이동: \(session.id)")
                coordinator.push(.report(sessionID: session.id))
            }
        }
        // ✅ 뷰가 나타날 때 store와 context를 실제 환경에 맞게 교체
        .onAppear {
            print("\n✅ FocusModeView 나타남")

            // 실제 SwiftData context로 ViewModel 교체
            updateViewModelContext()

            // 디버깅용 로깅
            print("현재 로드된 할 일 개수: \(viewModel.todos.count)")
            for (index, todo) in viewModel.todos.enumerated() {
                let setMinutes = viewModel.todoTimeSettings[todo.id] ?? 0
                let timeText = setMinutes > 0 ? "\(setMinutes)분" : "시간 없음"
                print("  \(index): \(todo.title) - \(timeText)")
            }
        }
    }

    /// 실제 context로 ViewModel의 store를 교체
    private func updateViewModelContext() {
        viewModel.replaceStoreWithContext(newContext: context)
    }
}

// ✅ 프리뷰용: 더미 UUID로 구성된 테스트 데이터 전달
#Preview {
    let context = try! ModelContainer(for: FocusSession.self).mainContext
    let input = FocusTodoInput(todoIDPairs: [
        (UUID(), 25),
        (UUID(), 0)
    ])
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.preview())
}
