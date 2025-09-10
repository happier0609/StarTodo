//
//  HistoryHeaderView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image("List")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
            Text("지난 집중 기록")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
            Text("최근 완료한 집중 세션을 확인해보세요")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
        }
    }
}

#Preview {
    HistoryHeaderView()
        .padding()
}
