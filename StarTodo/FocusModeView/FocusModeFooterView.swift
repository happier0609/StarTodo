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
