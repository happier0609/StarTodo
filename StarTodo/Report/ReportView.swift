//
//  ReportView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var coordinator: MainCoordinator
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
                todos: viewModel.todos,
                getComment: viewModel.timeDescription(for:),
                isCompleted: { $0.isCompleted }
            )
            .frame(maxHeight: 400)
            
            // ✅ 완료 버튼
            Button {
                viewModel.finalizeSession()   // 1. 세션 종료 처리
                coordinator.popToRoot()       // 2. 홈으로 이동
            } label: {
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
