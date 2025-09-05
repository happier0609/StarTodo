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
