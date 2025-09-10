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
                ForEach(viewModel.sessions, id: \.self) { session in
                    let data = HistoryCardViewData(session: session)
                    HistoryCardView(data: data)
                }
            }
            .padding()
        }
    }
}

#Preview {
    let previewSession = FocusSession(
        startedAt: Date().addingTimeInterval(-3600),
        endedAt: Date(),
        totalBreakSeconds: 0
    )
    previewSession.items = [
        FocusItem(title: "할일1", setSeconds: 0, elapsedSeconds: 0, isCompleted: true, order: 0),
        FocusItem(title: "할일2", setSeconds: 0, elapsedSeconds: 0, isCompleted: true, order: 1),
        FocusItem(title: "할일3", setSeconds: 0, elapsedSeconds: 0, isCompleted: false, order: 2)
    ]
    
    let viewModel = HistoryViewModel.preview([previewSession, previewSession])
    
    HistoryListView(viewModel: viewModel)
}
