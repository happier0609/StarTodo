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
            HStack(spacing: 8) {
                GlowingCheckButton(
                    isCompleted: isCompleted,
                    onTap: onComplete
                )
                
                Text("진행 중 \(title)")
                    .typo(.titleLGEmphasized)
                    .foregroundColor(Color("BgLight"))
                
                Spacer()
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
