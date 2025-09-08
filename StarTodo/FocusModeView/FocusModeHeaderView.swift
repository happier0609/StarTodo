//
//  FocusModeHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct FocusModeHeaderView: View {
    let statusText: String
    @ObservedObject var viewModel: FocusModeViewModel
    @State private var showExitConfirmation = false
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                Button("종료하기") { showExitConfirmation = true }
                    .foregroundColor(Color("Cool300"))
                    .typo(.textSMEmphasized)
                    .alert("정말 종료하시겠어요?", isPresented: $showExitConfirmation) {
                        Button("취소", role: .cancel) {}
                        Button("종료", role: .destructive) {
                            viewModel.endFocusSession()
                        }
                    } message: {
                        Text("지금까지의 집중 기록이 저장되고 종료됩니다.")
                    }
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
