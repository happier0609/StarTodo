//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusModeView: View {
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: FocusTab = .timer
    
    // ✅ 커스텀 생성자 (CoreData 제거)
    init(dummyTodos: [DummyTodo]) {
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(dummyTodos: dummyTodos))
    }
    
    var body: some View {
        ZStack {
            // ✅ 전체 배경
            Color("BgDark")
                .ignoresSafeArea()
            
            VStack {
                // 상단 종료 버튼 + 타이틀
                FocusModeHeaderView(
                    statusText: viewModel.headerStatusText,          // ← 추가한 계산 프로퍼티
                    onExit: { viewModel.endFocusSession() }
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
                if selectedTab == .timer {
                    FocusTimerView(viewModel: viewModel)
                } else {
                    FocusListView(viewModel: viewModel)
                }
                
                FocusModeFooterView(
                    expectedEndTimeString: viewModel.expectedEndTimeString,
                    isBreakActive: viewModel.isBreakActive
                ) {
                    if viewModel.isBreakActive {
                        viewModel.endBreakAndResume()             // 다시 시작하기
                    } else {
                        viewModel.showBreakSheet = true           // 휴식 알럿 표시
                    }
                }
            }
            // ✅ 종료 확인 알럿
            .alert("정말 종료할까요?", isPresented: $viewModel.showEndConfirmAlert) {
                Button("취소", role: .cancel) { }
                Button("종료하기", role: .destructive) {
                    viewModel.confirmEndSession()   // ← 타이머 정지 + (임시)저장 + 이동 트리거
                }
            } message: {
                Text("지금까지의 진행 상태를 저장한 뒤 리포트로 이동합니다.")
            }
            
//            // ✅ Report로 이동
//            NavigationLink(
//                destination: ReportView(
//                    viewModel: ReportViewModel(todos: viewModel.reportData),
//                    onComplete: {
//                        // 필요 시 메인으로 복귀 처리
//                    }
//                ),
//                isActive: $viewModel.shouldNavigateToReport
//            ) { EmptyView() }
//                .hidden()
        }
        .breakTimeAlert(
            isPresented: $viewModel.showBreakSheet,
            minutes: $viewModel.breakPickedMinutes
        ) {
            viewModel.startBreak(minutes: viewModel.breakPickedMinutes)
        }
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
            // (선택) 로컬 알림 권한 미리 요청하고 싶으면:
            //             viewModel.requestNotificationAuthorizationIfNeeded()
        }
    }
}

#Preview {
    FocusModeView(
        dummyTodos: [
            DummyTodo(id: UUID(), title: "영어 단어 외우기", setTime: 25, elapsed: 0, isCompleted: false),
            DummyTodo(id: UUID(), title: "수학 문제 풀기", setTime: 15, elapsed: 0, isCompleted: false),
        ]
    )
}



//MARK: - 기존코드 접기

//import SwiftUI
//import CoreData
//
//struct FocusModeView: View {
//    let todoIDPairs: [(UUID, Int)]
//    @StateObject private var viewModel: FocusModeViewModel
//
//    @State private var selectedTab: Tab = .timer
//
//    enum Tab {
//        case timer, list
//    }
//
//    // ✅ 커스텀 생성자 추가
//    init(todoIDPairs: [(UUID, Int)]) {
//        self.todoIDPairs = todoIDPairs
//        _viewModel = StateObject(wrappedValue: FocusModeViewModel(todoIDPairs: todoIDPairs))
//    }
//
//    var body: some View {
//        VStack {
//            // 상단 종료 버튼 + 타이틀
//            FocusModeHeaderView(
//                elapsedMinutes: viewModel.elapsedTotalMinutes,
//                onExit: {
//                    viewModel.endFocusSession()
//                }
//            )
//            NavigationLink(
//                destination: ReportView(
//                    viewModel: ReportViewModel(), // 새 인스턴스 또는 필요한 데이터를 전달
//                    onComplete: {
//                        // MainView로 돌아가기 위한 로직 (예: Navigation 상태 변경)
//                    }
//                ),
//                isActive: $viewModel.shouldNavigateToReport
//            ) {
//                EmptyView()
//            }
//            .hidden()
//
//            .padding()
//
//            // 세그먼티드 컨트롤
//            Picker("", selection: $selectedTab) {
//                Text("타이머").tag(Tab.timer)
//                Text("목록").tag(Tab.list)
//            }
//            .pickerStyle(.segmented)
//            .padding()
//
//            // 각 뷰 전환
//            if selectedTab == .timer {
//                FocusTimerView(viewModel: viewModel)
//            } else {
//                FocusListView(viewModel: viewModel)
//            }
//
//            FocusModeFooterView(
//                expectedEndTimeString: viewModel.expectedEndTimeString,
//                onRestTap: {
//                    viewModel.showBreakSheet = true
//                }
//            )
//        }
//    }
//}
