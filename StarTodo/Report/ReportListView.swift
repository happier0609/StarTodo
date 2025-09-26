//
//  ReportListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportListView: View {
    let timelineItems: [TimelineItemType]
    let incompletedTodos: [ReportItem]
    let viewModel: ReportViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - 타임라인 섹션 (완료된 할 일 + 휴식)
                if !timelineItems.isEmpty {
                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                        switch item {
                        case .todo(let reportItem):
                            todoRow(reportItem, isCompleted: true)
                        case .breakTime(let breakSession):
                            breakRow(breakSession)
                        }
                        
                        if index < timelineItems.count - 1 {
                            Divider()
                                .background(Color("Cool100").opacity(0.3))
                        }
                    }
                }
                
                // MARK: - 미완료 섹션
                if !incompletedTodos.isEmpty {
                    // 구분선
                    if !timelineItems.isEmpty {
                        HStack {
                            Rectangle()
                                .fill(Color("Cool100").opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    // 미완료 헤더
                    HStack {
                        Text("미완료 항목")
                            .typo(.textSMEmphasized)
                            .foregroundColor(Color("Cool100"))
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    // 미완료 아이템들
                    ForEach(Array(incompletedTodos.enumerated()), id: \.element.id) { index, todo in
                        todoRow(todo, isCompleted: false)
                        
                        if index < incompletedTodos.count - 1 {
                            Divider()
                                .background(Color("Cool100").opacity(0.3))
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - 할 일 행
    @ViewBuilder
    private func todoRow(_ todo: ReportItem, isCompleted: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 체크박스
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color("White"))
                        .frame(width: 24, height: 24)
                        .shadow(color: Color("White").opacity(0.8), radius: 6) // Glow 효과
                } else {
                    Circle()
                        .stroke(Color("Cool100"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.top, 2)
            
            // 텍스트 및 설명
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .typo(.textMDRegular)
                    .foregroundColor(isCompleted ? Color("BgLight") : Color("Cool100"))
                
                if let comment = viewModel.timeDescription(for: todo), isCompleted {
                    Text(comment)
                        .typo(.textSMEmphasized)
                        .foregroundColor(Color("Info200"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 휴식 행
    @ViewBuilder
    private func breakRow(_ breakSession: BreakSession) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 휴식 아이콘
            ZStack {
                Circle()
                    .fill(Color("Info200").opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "pause.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("Info200"))
            }
            .padding(.top, 2)
            
            // 휴식 정보
            VStack(alignment: .leading, spacing: 2) {
                Text("휴식")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Info200"))
                
                Text(viewModel.breakDescription(for: breakSession))
                    .typo(.textSMEmphasized)
                    .foregroundColor(breakSession.isOverdue ? Color("Warning200") : Color("Cool100"))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
