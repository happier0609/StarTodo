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
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.groupedSessions) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(section.title)  // "2025년 9월"
                            .font(.title3)
                            .bold()
                        
                        ForEach(section.sessions) { data in
                            HistoryCardView(data: data)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    let base = Date()  // 예: 2025-09-11
    
    // 📆 9월 세션
    let session1 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 10))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 11))!,
        totalBreakSeconds: 0
    )
    session1.items = [
        FocusItem(title: "9월 할일1", setSeconds: 600, elapsedSeconds: 600, isCompleted: true, order: 0),
        FocusItem(title: "9월 할일2", setSeconds: 900, elapsedSeconds: 900, isCompleted: true, order: 1)
    ]
    
    // 📆 8월 세션
    let session2 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 14))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 15))!,
        totalBreakSeconds: 300
    )
    session2.items = [
        FocusItem(title: "8월 할일1", setSeconds: 600, elapsedSeconds: 500, isCompleted: false, order: 0)
    ]
    
    let viewModel = HistoryViewModel.preview([session1, session2])
    return HistoryListView(viewModel: viewModel)
}
