//
//  HistoryView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/24/25.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    
    var body: some View {
        let viewModel = HistoryViewModel(context: context)
        
        VStack(spacing: 16) {
            HistoryHeaderView()
            Divider()
            HistoryListView(viewModel: viewModel)
        }
    }
}


struct Test_HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HistoryHeaderView()
            Divider()
            HistoryListView(viewModel: viewModel)
        }
    }
}

#Preview {
    // MARK: - 2025년 세션
    let session2025_09_1 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 10))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 10, hour: 11))!,
        totalBreakSeconds: 0
    )
    session2025_09_1.items = [
        FocusItem(title: "9월 할일1", setSeconds: 600, elapsedSeconds: 600, isCompleted: true, order: 0),
        FocusItem(title: "9월 할일2", setSeconds: 900, elapsedSeconds: 900, isCompleted: true, order: 1)
    ]
    
    let session2025_08_1 = FocusSession(
        startedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 14))!,
        endedAt: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 25, hour: 15))!,
        totalBreakSeconds: 300
    )
    session2025_08_1.items = [
        FocusItem(title: "8월 할일1", setSeconds: 600, elapsedSeconds: 500, isCompleted: false, order: 0)
    ]
    
    // MARK: - 2024년 세션
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
    let allSessions = [
        session2025_09_1, session2025_08_1,
        session2024_12, session2024_11
    ]
    let viewModel = HistoryViewModel.preview(allSessions)
    
    return Test_HistoryView(viewModel: viewModel)
}
