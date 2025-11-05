//
//  ReportView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI
import SwiftData

struct ReportView: View {
    let sessionID: PersistentIdentifier
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var coordinator: MainCoordinator
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // ✅ 더 나은 방법: @State + optional
    @State private var viewModel: ReportViewModel?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        ZStack {
            if loadFailed {
                errorView
            } else if isLoading {
                loadingView
            } else if let vm = viewModel {
                reportContent(viewModel: vm)
            }
        }
        .navigationTitle("집중 리포트")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") {
                    viewModel?.dismissReport()
                }
            }
        }
        .onAppear {
            loadSession()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("리포트를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("리포트를 불러올 수 없습니다")
                .font(.headline)
            
            Text("세션 데이터를 찾을 수 없습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("돌아가기") {
                coordinator.pop()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Report Content
    
    @ViewBuilder
    private func reportContent(viewModel: ReportViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                statisticsSection(viewModel: viewModel)
                timelineSection(viewModel: viewModel)
                todosSection(viewModel: viewModel)
            }
            .padding()
        }
    }
    
    private func statisticsSection(viewModel: ReportViewModel) -> some View {
        VStack(spacing: 12) {
            Text("총 집중 시간")
                .font(.headline)
            
            Text(viewModel.totalFocusedTimeText)
                .font(.system(size: 40, weight: .bold))
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(viewModel.completedCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("완료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.incompletedTodos.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("미완료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.breakCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("휴식")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func timelineSection(viewModel: ReportViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("타임라인")
                .font(.headline)
            
            ForEach(Array(viewModel.timelineItems.enumerated()), id: \.offset) { index, item in
                switch item {
                case .completed(let todo):
                    todoRow(todo: todo, isCompleted: true, viewModel: viewModel)
                case .incompleted(let todo):
                    todoRow(todo: todo, isCompleted: false, viewModel: viewModel)
                case .breakSession(let breakSession):
                    breakRow(breakSession: breakSession, viewModel: viewModel)
                }
            }
        }
    }
    
    private func todosSection(viewModel: ReportViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.completedTodos.isEmpty {
                Text("완료한 일")
                    .font(.headline)
                
                ForEach(viewModel.completedTodos, id: \.title) { todo in
                    todoRow(todo: todo, isCompleted: true, viewModel: viewModel)
                }
            }
            
            if !viewModel.incompletedTodos.isEmpty {
                Text("미완료한 일")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(viewModel.incompletedTodos, id: \.title) { todo in
                    todoRow(todo: todo, isCompleted: false, viewModel: viewModel)
                }
            }
        }
    }
    
    private func todoRow(todo: ReportItem, isCompleted: Bool, viewModel: ReportViewModel) -> some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(todo.title)
                    .font(.body)
                
                if let timeDesc = viewModel.timeDescription(for: todo) {
                    Text(timeDesc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(todo.elapsedSeconds / 60)분")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func breakRow(breakSession: BreakSession, viewModel: ReportViewModel) -> some View {
        HStack {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundColor(.blue)
            
            Text("휴식")
                .font(.body)
            
            Spacer()
            
            Text(viewModel.breakDescription(for: breakSession))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Load Session
    
    private func loadSession() {
        print("📊 ReportView: 세션 로딩 시작")
        
        // ✅ Static factory method로 세션 로드
        if let vm = ReportViewModel.load(
            sessionID: sessionID,
            context: context,
            coordinator: coordinator,
            mainViewModel: mainViewModel
        ) {
            viewModel = vm
            isLoading = false
            loadFailed = false
            
            print("✅ ReportView: 세션 로딩 완료")
        } else {
            isLoading = false
            loadFailed = true
            
            print("⚠️ ReportView: 세션 로딩 실패")
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("ReportView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, configurations: config)
    let context = container.mainContext
    
    // ✅ 샘플 세션 생성 (올바른 방법)
    let session = FocusSession(
        startedAt: Date().addingTimeInterval(-3600),  // 1시간 전
        endedAt: Date()
    )
    context.insert(session)
    
    // ✅ FocusItem 생성 및 추가
    let item1 = FocusItem(
        title: "운동하기",
        setSeconds: 1800,
        elapsedSeconds: 1500,
        isCompleted: true,
        order: 0
    )
    session.items.append(item1)
    
    let item2 = FocusItem(
        title: "독서하기",
        setSeconds: 2400,
        elapsedSeconds: 2400,
        isCompleted: true,
        order: 1
    )
    session.items.append(item2)
    
    // ✅ BreakSession 생성 및 추가
    let breakSession = BreakSession(
        start: Date().addingTimeInterval(-1800),  // 30분 전
        end: Date().addingTimeInterval(-1500),    // 25분 전
        isOverdue: false
    )
    session.breaks.append(breakSession)
    
    // 저장
    try? context.save()
    
    let mainVM = MainViewModel(context: context)
    
    return ReportView(sessionID: session.persistentModelID)
        .environmentObject(MainCoordinator.shared)
        .environmentObject(mainVM)
        .modelContainer(container)
}
#endif
