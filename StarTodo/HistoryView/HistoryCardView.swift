//
//  HistoryCardView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2025년 9월 8일 (월)")
                .font(.headline)
            Text("집중 시간: 75분 · 완료한 일: 4개")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HistoryCardView()
        .padding()
}
