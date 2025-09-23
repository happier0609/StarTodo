//
//  BreakInfoBubble.swift
//  StarTodo
//
//  Created by 조민경 on 8/19/25.
//

import SwiftUI

struct BreakInfoBubble: View {
    var body: some View {
        Text("다시 탐사를 진행하기 위해\n몸과 정신을 충전하자…")
            .multilineTextAlignment(.center)
            .foregroundColor(Color("App.White"))
            .typo(.textMDRegular)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("Cool900"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(Color("App.White")).opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 28)
    }
}
