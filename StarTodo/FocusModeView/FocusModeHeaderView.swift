//
//  FocusModeHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct FocusModeHeaderView: View {
    let statusText: String
    @StateObject private var viewModel: FocusModeViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                Button("종료하기") { viewModel.endFocusSession() }
                    .foregroundColor(Color("Cool300"))
                    .typo(.textSMEmphasized)
            }
            .padding()
            
            HStack(spacing: 4) {
                Image("Working")
                Text(statusText)
            }
            .foregroundColor(Color("Info400"))
            .typo(.textMDEmphasized)
            .padding(.top, 4)
            
        }
    }
}
