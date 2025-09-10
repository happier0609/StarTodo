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
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.groupedByYear) { yearSection in
                    VStack(alignment: .leading, spacing: 24) {
                        // 🔷 연도 타이틀 (예: "2025년")
                        Text(yearSection.title)
                            .font(.title2)
                            .bold()
                            .padding(.top, 8)
                        
                        ForEach(yearSection.months) { monthSection in
                            VStack(alignment: .leading, spacing: 16) {
                                // 🔹 월 타이틀 (예: "9월")
                                Text(monthSection.title)
                                    .font(.title3)
                                    .bold()
                                
                                ForEach(monthSection.sessions) { data in
                                    HistoryCardView(data: data)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    // MARK: - 📅 2025년 세션들
    let session2025_09 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 10))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 11))!,
        totalBreakSeconds: 0
    )
    session2025_09.items = [
        FocusItem(title: "9월 할일1", setSeconds: 600, elapsedSeconds: 600, isCompleted: true, order: 0),
        FocusItem(title: "9월 할일2", setSeconds: 900, elapsedSeconds: 900, isCompleted: true, order: 1)
    ]
    
    let session2025_08 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 14))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 15))!,
        totalBreakSeconds: 300
    )
    session2025_08.items = [
        FocusItem(title: "8월 할일1", setSeconds: 600, elapsedSeconds: 500, isCompleted: false, order: 0)
    ]

    // MARK: - 📅 2024년 세션들
    let session2024_12 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 5, hour: 9))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 5, hour: 10))!,
        totalBreakSeconds: 180
    )
    session2024_12.items = [
        FocusItem(title: "12월 할일1", setSeconds: 1200, elapsedSeconds: 1100, isCompleted: true, order: 0)
    ]
    
    let session2024_11 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 20, hour: 15))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 20, hour: 16))!,
        totalBreakSeconds: 0
    )
    session2024_11.items = [
        FocusItem(title: "11월 할일1", setSeconds: 900, elapsedSeconds: 600, isCompleted: false, order: 0),
        FocusItem(title: "11월 할일2", setSeconds: 600, elapsedSeconds: 600, isCompleted: true, order: 1)
    ]

    // MARK: - ViewModel 구성
    let allSessions = [session2025_09, session2025_08, session2024_12, session2024_11]
    let viewModel = HistoryViewModel.preview(allSessions)
    
    return HistoryListView(viewModel: viewModel)
}
