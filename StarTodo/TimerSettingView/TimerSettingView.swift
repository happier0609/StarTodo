//
//  TimerSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import SwiftUI

struct TimerSettingView: View {
    @State private var viewModel: TimerSettingViewModel

    @State private var navigateToFocus = false

    // ✅ 생성자에서 ViewModel 주입
    init(selectedIDs: [UUID], allTodos: [Todo]) {
        _viewModel = State(initialValue: TimerSettingViewModel(selectedTodoIDs: selectedIDs, allTodos: allTodos))
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("목록을 확인하고")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
            Text("목표 시간을 설정해주세요")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
        }

        VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 12) {
                    // ✅ 선택된 Todo 목록 표시
                    ForEach(viewModel.selectedTodos, id: \.id) { todo in
                        let parentTitle = todo.parent?.title

                        TimerItemRowView(
                            item: todo,
                            parentTitle: parentTitle,
                            selectedTime: viewModel.selectedTimes[todo.id] ?? nil,
                            onTimeChange: { viewModel.selectedTimes[todo.id] = $0 }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // ✅ 총 시간 표시
            let totalMinutes = viewModel.totalSelectedMinutes
            let hour = totalMinutes / 60
            let minute = totalMinutes % 60
            let timeString = (hour > 0 ? "\(hour)시간 " : "") + "\(minute)분"

            HStack(spacing: 0) {
                Text("\(timeString)")
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("Primary600"))
                Text(" 소요 예정")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool1100"))
            }

            // ✅ 시작 버튼
            Button(action: {
                navigateToFocus = true
            }) {
                Text("이대로 시작하기")
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("White"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("Primary600"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)

//            // ✅ NavigationLink
//            NavigationLink(
//                destination: FocusModeView(todoIDPairs: viewModel.todoIDPairsToPass),
//                isActive: $navigateToFocus,
//                label: { EmptyView() }
//            )
//            .hidden()
        }
        .padding(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("List")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
    }
}
