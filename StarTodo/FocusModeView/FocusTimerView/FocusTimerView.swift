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
                    isCompleted: viewModel.isCurrentTodoCompleted,
                    remainingTime: viewModel.remainingTimeString,
                    onComplete: {
                        viewModel.completeCurrentTodo()
                    }
                )
            } else {
                Text("진행할 할 일이 없습니다.")
                    .foregroundColor(Color("Cool300"))
            }

            // 원형 타이머: 휴식/집중 공용 표시 값 사용
            CircularTimerView(
                setTime: viewModel.displaySetMinutes,
                elapsedTime: viewModel.displayElapsedSeconds
            )
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isBreakActive)
    }
}

// 디버깅을 위한 추가 정보 표시 (개발 중에만)
#if DEBUG
extension FocusTimerView {
    private var debugInfo: some View {
        VStack {
            if let todo = viewModel.currentTodo {
                Text("디버그: \(todo.title)")
                Text("설정 시간: \(viewModel.currentSetMinutes)분")
                Text("경과 시간: \(viewModel.currentElapsedSeconds)초")
                Text("완료 상태: \(viewModel.isCurrentTodoCompleted ? "완료" : "진행중")")
            }
        }
        .font(.caption)
        .foregroundColor(.yellow)
    }
}
#endif
