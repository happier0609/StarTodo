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
                .foregroundColor(Color("App.White"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                )

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary500"))
                        .padding(6)
                        .background(Circle().fill(Color("App.White")))
                        .offset(x: 2, y: -8)
                }
            }
        }
        .disabled(selectedCount == 0)
    }
}

#if DEBUG
import SwiftUI

#Preview("선택된 항목 있음") {
    FocusStartButton(selectedCount: 2) {
        print("버튼 눌림")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}

#Preview("선택된 항목 없음") {
    FocusStartButton(selectedCount: 0) {
        print("버튼 눌림")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}

#endif
