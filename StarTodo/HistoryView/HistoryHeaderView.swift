//
//  HistoryHeaderView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 지난 집중 기록")
                .font(.title2)
                .bold()
            Text("최근 완료한 집중 세션을 확인해보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HistoryHeaderView()
        .padding()
}
