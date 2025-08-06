//
//  FocusTimerHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI

struct FocusTimerHeaderView: View {
    let title: String
    let isCompleted: Bool
    let remainingTime: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                GlowingCheckButton(
                    isCompleted: isCompleted,
                    onTap: onComplete
                )
                
                Text("\(title)")
                    .typo(.titleLGEmphasized)
                    .foregroundColor(Color("BgLight"))
            }
            
            HStack(spacing: 0){
                Text("남은 시간 ")
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool300"))
                
                Text("\(remainingTime)")
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Info1100"))
            }
        }
        .padding(.horizontal)
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
