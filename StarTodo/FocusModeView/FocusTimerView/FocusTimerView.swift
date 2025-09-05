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
            // ⬇️ 상단 영역: 휴식 중이면 버블, 아니면 기존 헤더
            if viewModel.isBreakActive {
                BreakInfoBubble()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let current = viewModel.currentTodo {
                FocusTimerHeaderView(
                    title: current.title,
                    isCompleted: current.isCompleted,
                    remainingTime: viewModel.remainingTimeString,
                    onComplete: {
                        viewModel.completeCurrentTodo()
                    }
                )
            } else {
                Text("진행할 할 일이 없습니다.")
                    .foregroundColor(Color("Cool300"))
            }

            // ⬇️ 원형 타이머: 휴식/집중 공용 표시 값 사용
            CircularTimerView(
                setTime: viewModel.displaySetMinutes,
                elapsedTime: viewModel.displayElapsedSeconds
            )
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isBreakActive)
    }
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
