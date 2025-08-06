//
//  FocusTimerView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusTimerView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        VStack(spacing: 20) {
            if let current = viewModel.currentTodo {
                FocusTimerHeaderView(
                    title: current.title,
                    isCompleted: current.isCompleted,
                    remainingTime: viewModel.remainingTimeString,
                    onComplete: {
                        viewModel.markCurrentTodoAsCompleted()
                    }
                )

                // 타이머 뷰 (원형)
                CircularTimerView(
                    setTime: current.setTime,
                    elapsedTime: current.elapsed
                )
            } else {
                Text("진행할 할 일이 없습니다.")
            }
        }
        .sheet(isPresented: $viewModel.showBreakSheet) {
            // BreakSettingSheet(viewModel: viewModel)
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

//MARK: - 기존코드

//import SwiftUI
//
//struct FocusTimerView: View {
//    @ObservedObject var viewModel: FocusModeViewModel
//
//    var body: some View {
//        VStack(spacing: 20) {
//            FocusTimerHeaderView(
//                title: viewModel.currentTodo.todo.wrappedTitle,
//                isCompleted: viewModel.currentTodo.isCompleted,
//                remainingTime: viewModel.remainingTimeString,
//                onComplete: {
//                    viewModel.markCurrentTodoAsCompleted()
//                }
//            )
//
//            // 타이머 뷰 (원형)
//            CircularTimerView(
//                setTime: viewModel.currentTodo.setTime,
//                elapsedTime: viewModel.currentTodo.elapsed
//            )
//
//            // 잠깐 쉬기 버튼
//            Button(action: {
//                viewModel.showBreakSheet = true
//            }) {
//                Label("잠깐 쉬기", systemImage: "rocket")
//            }
//            .disabled(viewModel.isBreakActive)
//
//            // 예상 종료 시간
//            Text("예상 종료 시간 \(viewModel.expectedEndTimeString)")
//                .font(.footnote)
//                .foregroundColor(.blue)
//        }
//        .sheet(isPresented: $viewModel.showBreakSheet) {
////            BreakSettingSheet(viewModel: viewModel)
//        }
//    }
//}
