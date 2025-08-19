//
//  BreakEndOverlay.swift
//  StarTodo
//
//  Created by 조민경 on 8/19/25.
//

import SwiftUI

struct BreakEndOverlay: View {
    let onReturn: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())   // 배경 터치 차단

            VStack(spacing: 16) {
                Text("휴식 시간 종료!")
                    .font(.title).bold()
                    .foregroundColor(.white)

                Button(action: onReturn) {
                    HStack(spacing: 8) {
                        Image(systemName: "rocket.fill")
                        Text("할 일로 돌아가기")
                            .font(.headline).bold()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
                    .background(Color("Primary500"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            .padding(28)
            .background(Color("Cool1000"))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 32)
            .shadow(radius: 30)
        }
    }
}
