//
//  FocusTimerHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI

struct FocusTimerHeaderView: View {
    let title: String
    let isCompleted: Bool
    let remainingTime: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                GlowingCheckButton(
                    isCompleted: isCompleted,
                    onTap: onComplete
                )
                
                ZStack {
                    Text(title)
                        .typo(.titleLGEmphasized)
                        .foregroundColor(Color("BgLight"))

                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color("App.White"))
                            .frame(height: 2)
                            .frame(width: isCompleted ? geo.size.width : 0) // 너비를 애니메이션
                            .offset(y: geo.size.height / 2) // 텍스트 중간에 맞추기
                            .animation(.easeInOut(duration: 0.3), value: isCompleted)
                    }
                    .allowsHitTesting(false) // 버튼 등의 인터랙션 방해하지 않도록
                }
                .fixedSize() // ⬅️ 텍스트 크기만큼만 ZStack 크기 고정
            }
            
            HStack(spacing: 0){
                Text("남은 시간 ")
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool300"))
                
                Text("\(remainingTime)")
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Info1100"))
            }
        }
        .padding(.horizontal)
    }
}
