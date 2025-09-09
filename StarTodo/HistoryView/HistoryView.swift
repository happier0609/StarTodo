//
//  HistoryView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/24/25.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 0) {
            HistoryHeaderView()
            HistoryListView()
        }
        .padding()
    }
}

#Preview {
    HistoryView()
}
