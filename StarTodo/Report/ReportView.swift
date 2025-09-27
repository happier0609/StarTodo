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
            
            ZStack {
                Rectangle()
                    .cornerRadius(16)
                    .foregroundColor(Color("Cool1000"))
                
                // ✅ 리스트 뷰 (타임라인 형식으로 업데이트)
                ReportListView(
                    timelineItems: viewModel.timelineItems,
                    incompletedTodos: viewModel.incompletedTodos,
                    viewModel: viewModel
                )
                .frame(maxHeight: 390)
            }
            .frame(maxHeight: 420)
            
            // ✅ 완료 버튼
            Button {
                viewModel.finalizeSession()
                
                // 1. fullscreen 닫기
                coordinator.dismissFullScreen()
                
                // 2. NavigationStack 초기화 (루트로 이동)
                coordinator.popToRoot()
            } label: {
                Text("완료하기")
                    .typo(.textMDEmphasized)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Info300"))
                    .foregroundColor(Color("App.White"))
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color("BgDark"))
        
        // Back 버튼 숨기기, 잠금 상태 만들기
        .navigationBarBackButtonHidden(true)
        .focusLocked()
    }
}

