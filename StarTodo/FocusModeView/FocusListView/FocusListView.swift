//
//  FocusListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusListView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.sortedTodosForListView.enumerated()), id: \.offset) { index, todo in
                        FocusListRowView(
                            title: todo.title,
                            isCompleted: todo.isCompleted,
                            isCurrent: todo.id == viewModel.currentTodo?.id,
                            onComplete: {
                                viewModel.markCurrentTodoAsCompleted()
                            }
                        )
                        .onTapGesture {
                            viewModel.selectTodo(at: index)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("Cool1000"))
                )
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

#Preview {
    let dummyTodos = [
        DummyTodo(id: UUID(), title: "수학 문제 풀기", setTime: 25, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "영어 단어 외우기", setTime: 20, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "울라랄라라라ㅏ", setTime: 15, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "우아아ㅏ아아ㅏㅇ", setTime: 15, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "뿌아앙ㅇㅇㅇ", setTime: 15, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "ㄱㄱㄱㄱㄱㄱㄱㄱ", setTime: 15, elapsed: 0, isCompleted: false)
    ]
    let viewModel = FocusModeViewModel(dummyTodos: dummyTodos)

    return FocusListView(viewModel: viewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgDark"))
}
