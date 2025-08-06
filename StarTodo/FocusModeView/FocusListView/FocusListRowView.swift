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
    
    // ✅ 텍스트 색상을 상태에 따라 결정
        private var titleColor: Color {
            if isCompleted {
                return Color("Cool600")
            } else if isCurrent {
                return Color("BgLight")
            } else {
                return Color("Cool200")
            }
        }

    var body: some View {
        HStack(spacing: 12) {
            GlowingCheckButton(
                isCompleted: isCompleted,
                onTap: onComplete
            )

            Text(title)
                .foregroundColor(titleColor)
                .typo(.textLGEmphasized)

            Spacer()
        }
        .padding()
        .background(isCurrent ? Color("Cool600") : Color.clear)
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
