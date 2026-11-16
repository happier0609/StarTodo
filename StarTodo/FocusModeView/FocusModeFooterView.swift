//
//  FocusModeFooterView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct FocusModeFooterView: View {
    let expectedEndTimeString: String
    let isBreakActive: Bool
    let onRestTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onRestTap) {
                Image(isBreakActive ? "ReStart" : "Rest")
                    .frame(height: 50)
            }
            
            HStack {
                Text("예상 종료 시간")
                    .foregroundColor(Color("Cool600"))
                    .typo(.textSMRegular)
                
                Text("\(expectedEndTimeString)")
                    .foregroundStyle(Color("Info400"))
                    .typo(.textSMEmphasized)
            }
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    VStack(spacing: 28) {
        // 휴식 중
        FocusModeFooterView(
            expectedEndTimeString: "오후 4:40",
            isBreakActive: true,
            onRestTap: {}
        )

        // 휴식 아님
        FocusModeFooterView(
            expectedEndTimeString: "오후 4:40",
            isBreakActive: false,
            onRestTap: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BgDark"))
}
