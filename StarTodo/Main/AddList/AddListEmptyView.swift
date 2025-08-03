//
//  AddListEmptyView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/24/25.
//

import SwiftUI

struct AddListEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("Empty") // 🐻: 에셋 이름에 맞게 수정해줘!
                .resizable()
                .scaledToFit()
                .frame(width: 160)

            Text("완벽보다 중요한 건 시작하는 용기.\n지금 해낼 수 있는 일들을 선택해요")
                .typo(.textSMRegular)
                .foregroundColor(Color("Info1200"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AddListEmptyView()
}
