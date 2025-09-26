//
//  ReportListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportListView: View {
    let timelineItems: [ReportRowType]
    let incompletedTodos: [ReportItem]
    let viewModel: ReportViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - 타임라인 섹션 (완료된 할 일 + 휴식)
                if !timelineItems.isEmpty {
                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                        ReportListRowView(
                            type: item,
                            viewModel: viewModel
                        )
                        
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
                        ReportListRowView(
                            type: .incompleted(todo),
                            viewModel: viewModel
                        )
                        
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
}
