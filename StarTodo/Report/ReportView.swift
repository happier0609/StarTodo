//
//  ReportView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI
import CoreData

struct ReportView: View {
    @ObservedObject var viewModel: ReportViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ReportHeaderView(
                totalTasks: viewModel.todos.count,
                completedTasks: viewModel.completedTodos.count,
                totalHours: viewModel.totalFocusedTime / 60,
                totalMinutes: viewModel.totalFocusedTime % 60
            )
            .padding(.bottom)

            // ✅ 리스트 뷰
            ReportListView(
                todos: viewModel.todos,
                getComment: viewModel.timeDescription(for:),
                isCompleted: { $0.isCompleted }
            )
            .frame(maxHeight: 400)

            // ✅ 완료 버튼
            Button(action: onComplete) {
                Text("완료하기")
                    .typo(.textMDEmphasized)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Info300"))
                    .foregroundColor(Color("White"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color("BgDark"))
        .foregroundColor(.white)
    }
}
