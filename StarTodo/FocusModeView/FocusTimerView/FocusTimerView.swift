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
            FocusTimerHeaderView(
                title: viewModel.currentTodo.todo.wrappedTitle,
                isCompleted: viewModel.currentTodo.isCompleted,
                remainingTime: viewModel.remainingTimeString,
                onComplete: {
                    viewModel.markCurrentTodoAsCompleted()
                }
            )

            // 타이머 뷰 (원형)
            CircularTimerView(
                setTime: viewModel.currentTodo.setTime,
                elapsedTime: viewModel.currentTodo.elapsed
            )

            // 잠깐 쉬기 버튼
            Button(action: {
                viewModel.showBreakSheet = true
            }) {
                Label("잠깐 쉬기", systemImage: "rocket")
            }
            .disabled(viewModel.isBreakActive)

            // 예상 종료 시간
            Text("예상 종료 시간 \(viewModel.expectedEndTimeString)")
                .font(.footnote)
                .foregroundColor(.blue)
        }
        .sheet(isPresented: $viewModel.showBreakSheet) {
//            BreakSettingSheet(viewModel: viewModel)
        }
    }
}
