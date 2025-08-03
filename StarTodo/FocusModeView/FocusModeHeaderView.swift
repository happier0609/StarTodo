//
//  FocusModeHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct FocusModeHeaderView: View {
    let elapsedMinutes: Int
    let onExit: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button("종료하기") {
                onExit()
            }
            .foregroundColor(Color("Cool300"))
            .typo(.textSMEmphasized)
        }
        .padding(.horizontal)

        HStack(spacing: 4) {
            Image("Working")
            Text("\(elapsedMinutes)분 째 탐사 중...")
        }
        .foregroundColor(Color("Info400"))
        .typo(.textSMEmphasized)
        .padding(.top, 4)
    }
}
