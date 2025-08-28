//
//  ReportView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportView: View {
    @ObservedObject var viewModel: ReportViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 상단 요약 헤더
            ReportHeaderView(
                totalTasks: viewModel.todos.count,
                completedTasks: viewModel.completedCount,
                totalHours: viewModel.totalFocusedMinutes / 60,   // 분 → 시/분 분해
                totalMinutes: viewModel.totalFocusedMinutes % 60
            )
            .padding(.bottom)

            // (선택) 총 계획 대비 결과 코멘트가 있으면 노출
            if let msg = viewModel.timeComparisonMessage {
                Text(msg)
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Info400"))
            }

            // ✅ 리스트 뷰
            ReportListView(
                todos: viewModel.todos,                          // [Todo]
                getComment: viewModel.timeDescription(for:),     // (Todo) -> String?
                isCompleted: { $0.isCompleted }                  // 완료 여부
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
