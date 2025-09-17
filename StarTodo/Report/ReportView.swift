//
//  ReportView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI
import SwiftData

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

#Preview {
    do {
        let context = try defaultContext

        // 1. 더미 FocusSession 생성
        let dummySession = FocusSession(
            startedAt: .now.addingTimeInterval(-1800),
            endedAt: .now,
            totalBreakSeconds: 600
        )
        context.insert(dummySession)

        // 2. ID 추출
        let id = dummySession.persistentModelID

        return ReportView(
            viewModel: ReportViewModel(sessionID: id),
            onComplete: {}
        )
        .environmentObject(MainCoordinator.preview())
        
    } catch {
        // 에러 발생 시 Text View 반환
        return Text("프리뷰 실패: \(error.localizedDescription)")
    }
}
