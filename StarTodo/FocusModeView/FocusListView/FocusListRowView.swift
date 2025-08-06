//
//  FocusListRowView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI

struct FocusListRowView: View {
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack {
            GlowingCheckButton(
                isCompleted: isCompleted,
                onTap: onComplete
            )

            Text(title)
                .foregroundColor(isCompleted ? Color("Cool600") : Color("BgLight"))
                .typo(.textLGEmphasized)

            Spacer()
        }
        .padding()
        .background(isCurrent ? Color("Cool100") : Color.clear)
        .cornerRadius(10)
    }
}

#Preview {
    let dummyTodos = [
        DummyTodo(id: UUID(), title: "수학 문제 풀기", setTime: 25, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "영어 단어 외우기", setTime: 20, elapsed: 0, isCompleted: false),
        DummyTodo(id: UUID(), title: "과학 정리하기", setTime: 15, elapsed: 0, isCompleted: true)
    ]
    let viewModel = FocusModeViewModel(dummyTodos: dummyTodos)

    return FocusListView(viewModel: viewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgDark"))
}
