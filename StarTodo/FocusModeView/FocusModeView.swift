//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusModeView: View {
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: Tab = .timer

    enum Tab {
        case timer, list
    }

    // ✅ 커스텀 생성자 (CoreData 제거)
    init(dummyTodos: [DummyTodo]) {
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(dummyTodos: dummyTodos))
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
            .padding()

            // 세그먼티드 컨트롤
            Picker("", selection: $selectedTab) {
                Text("타이머").tag(Tab.timer)
                Text("목록").tag(Tab.list)
            }
            .pickerStyle(.segmented)
            .padding()

            // 화면 전환
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
