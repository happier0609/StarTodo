//
//  GlowingCheckButton.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI

struct GlowingCheckButton: View {
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color("White"))
                        .frame(width: 24, height: 24)
                        .shadow(color: Color("White").opacity(0.8), radius: 6) // Glow 효과
                } else {
                    Circle()
                        .stroke(Color("Cool100"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}
