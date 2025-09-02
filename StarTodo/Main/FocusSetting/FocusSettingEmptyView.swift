//
//  FocusSettingEmptyView.swift
//  StarTodo
//
//  Created by 조민경 on 9/1/25.
//

import SwiftUI

struct FocusSettingEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("Empty")
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
