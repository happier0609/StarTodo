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
