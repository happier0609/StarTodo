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
        .typo(.textMDEmphasized)
        .padding(.top, 4)
    }
}

#Preview {
    VStack {
        FocusModeHeaderView(elapsedMinutes: 12, onExit: {
            print("종료하기 버튼 눌림")
        })
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BgDark"))
}
