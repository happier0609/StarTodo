//
//  TypoTestView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/22/25.
//

import SwiftUI

struct TypographyTestView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("textSMEmphasized")
                .typo(.textSMEmphasized)

            Text("textMDRegular")
                .typo(.textMDRegular)
            
            Text("textMDEmphasized")
                .typo(.textMDEmphasized)

            Text("titleLGEmphasized")
                .typo(.titleLGEmphasized)

            Text("alarmTitle")
                .typo(.alarmTitle)

            Text("spartanBold")
                .typo(.spartanBold)
        }
        .padding()
    }
}

#Preview {
    TypographyTestView()
}

