//
//  FocusModeFooterView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct FocusModeFooterView: View {
    let expectedEndTimeString: String
    let onRestTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button(action: onRestTap) {
                Label("잠깐 쉬기", systemImage: "rocket")
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.gray)
                    .clipShape(Capsule())
            }

            Text("예상 종료 시간  \(expectedEndTimeString)")
                .foregroundColor(Color("Primary500"))
                .typo(.textSMRegular)
        }
        .padding(.bottom, 20)
    }
}
