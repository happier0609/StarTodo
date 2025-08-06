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
                Image("Rest")
                    .frame(height: 50)
            }
            
            Text("예상 종료 시간  \(expectedEndTimeString)")
                .foregroundColor(Color("Primary500"))
                .typo(.textSMRegular)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    VStack {
        Spacer()
        
        FocusModeFooterView(
            expectedEndTimeString: "오후 3:30",
            onRestTap: {
                print("🛑 쉬기 버튼 눌림")
            }
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BgDark")) // 실제 배경 컬러에 맞게 조정
}
