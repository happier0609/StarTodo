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
            // 상단 요약 헤더 (기존 ReportHeaderView 그대로 사용)
            ReportHeaderView(
                totalTasks: viewModel.todos.count,
                completedTasks: viewModel.completedCount,
                totalHours: viewModel.totalFocusedMinutes / 60,
                totalMinutes: viewModel.totalFocusedMinutes % 60
            )
            .padding(.bottom)
            
            // ✅ 리스트 뷰 (타임라인 형식으로 업데이트)
            ReportListView(
                timelineItems: viewModel.timelineItems,
                incompletedTodos: viewModel.incompletedTodos,
                viewModel: viewModel
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
        
        // Back 버튼 숨기기, 잠금 상태 만들기
        .navigationBarBackButtonHidden(true)
        .focusLocked()
    }
}

#Preview {
    do {
        let context = try defaultContext

        // 1. 더미 FocusSession 생성
        let dummySession = FocusSession(
            startedAt: .now.addingTimeInterval(-3600),
            endedAt: .now,
            totalBreakSeconds: 600
        )
        
        // 더미 아이템 추가
        let item1 = FocusItem(
            title: "완료한 작업 1",
            setSeconds: 1200,
            elapsedSeconds: 1300,
            isCompleted: true,
            order: 0
        )
        let item2 = FocusItem(
            title: "완료한 작업 2",
            setSeconds: 900,
            elapsedSeconds: 850,
            isCompleted: true,
            order: 1
        )
        let item3 = FocusItem(
            title: "미완료 작업",
            setSeconds: 600,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 2
        )
        dummySession.items = [item1, item2, item3]
        
        // 더미 휴식 추가
        let break1 = BreakSession(
            start: .now.addingTimeInterval(-2400),
            end: .now.addingTimeInterval(-2100),
            isOverdue: false
        )
        let break2 = BreakSession(
            start: .now.addingTimeInterval(-1200),
            end: .now.addingTimeInterval(-900),
            isOverdue: true
        )
        dummySession.breaks = [break1, break2]
        
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
