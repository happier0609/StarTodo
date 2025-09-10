//
//  HistoryListView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryListView: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    ForEach(viewModel.cardViewDataList) { data in
                        HistoryCardView(data: data)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    let session1 = FocusSession(
        startedAt: Date().addingTimeInterval(-3600),
        endedAt: Date(),
        totalBreakSeconds: 0
    )
    session1.items = [
        FocusItem(title: "할일1", setSeconds: 600, elapsedSeconds: 600, isCompleted: true, order: 0),
        FocusItem(title: "할일2", setSeconds: 900, elapsedSeconds: 900, isCompleted: true, order: 1)
    ]
    
    let session2 = FocusSession(
        startedAt: Date().addingTimeInterval(-7200),
        endedAt: Date().addingTimeInterval(-3600),
        totalBreakSeconds: 120
    )
    session2.items = [
        FocusItem(title: "할일3", setSeconds: 600, elapsedSeconds: 500, isCompleted: false, order: 0)
    ]
    
    let viewModel = HistoryViewModel.preview([session1, session2])
    
    return HistoryListView(viewModel: viewModel)
}
