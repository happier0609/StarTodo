//
//  FocusStartButton.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/29/25.
//

import Foundation
import SwiftUI

struct FocusStartButton: View {
    let selectedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Text("집중모드 시작")
                        .font(.headline)
                    Image(selectedCount > 0 ? "Start" : "noneStart") // 🔹 조건부 에셋
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(selectedCount > 0 ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                )

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.white))
                        .overlay(
                            Circle().stroke(Color.blue, lineWidth: 2)
                        )
                        .offset(x: 10, y: -10)
                }
            }
        }
        .disabled(selectedCount == 0)
    }
}
