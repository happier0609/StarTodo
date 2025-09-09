//
//  HistoryListView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<5) { index in
                    HistoryCardView()
                }
            }
        }
    }
}

#Preview {
    HistoryListView()
        .padding()
}
