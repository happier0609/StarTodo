//
//  ReportView.swift
//  StarTodo
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
    @State private var isSaving = false
    
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
        .background(Color("BgDark"))
        .navigationBarBackButtonHidden(true)
        .focusLocked()
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
                coordinator.dismissFullScreen()
                coordinator.popToRoot()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Report Content
    
    @ViewBuilder
    private func reportContent(viewModel: ReportViewModel) -> some View {
        VStack(spacing: 20) {
            // 상단 요약 헤더
            ReportHeaderView(
                totalTasks: viewModel.todos.count,
                completedTasks: viewModel.completedCount,
                totalHours: viewModel.totalFocusedMinutes / 60,
                totalMinutes: viewModel.totalFocusedMinutes % 60
            )
            .padding(.bottom, 4)
            
            // 리스트 영역 (둥근 박스)
            ZStack {
                Rectangle()
                    .cornerRadius(16)
                    .foregroundColor(Color("Cool1000"))
                
                ReportListView(
                    timelineItems: viewModel.timelineItems,
                    incompletedTodos: viewModel.incompletedTodos,
                    viewModel: viewModel
                )
                .frame(maxHeight: 390)
            }
            .frame(maxHeight: 420)
            
            // 완료하기 버튼
            Button {
                Task {
                    isSaving = true
                    
                    // 1. 세션 종료 및 저장 (완료될 때까지 대기)
                    await viewModel.finalizeSession()
                    
                    // 2. 저장 완료 후 짧은 대기 (변경사항 전파 보장)
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15초
                    
                    // 3. 메인 스레드에서 화면 전환
                    await MainActor.run {
                        isSaving = false
                        
                        // 4. fullscreen 닫기
                        coordinator.dismissFullScreen()
                        
                        // 5. NavigationStack 초기화 (루트로 이동)
                        coordinator.popToRoot()
                    }
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("저장 중...")
                    } else {
                        Text("완료하기")
                    }
                }
                .typo(.textMDEmphasized)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSaving ? Color.gray : Color("Info300"))
                .foregroundColor(Color("App.White"))
                .cornerRadius(16)
            }
            .disabled(isSaving)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
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
import SwiftUI
import SwiftData

// MARK: - 기본 프리뷰
#Preview("기본 - 완료/미완료 혼합") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, FocusItem.self, BreakSession.self, configurations: config)
    let context = container.mainContext
    
    // ✅ 샘플 세션 생성
    let session = PreviewReportData.createSimpleMockSession(in: context)
    try? context.save()
    
    let mainVM = MainViewModel(context: context)
    
    return ReportView(sessionID: session.persistentModelID)
        .environmentObject(MainCoordinator.shared)
        .environmentObject(mainVM)
        .modelContainer(container)
}

// MARK: - 전체 데이터 프리뷰
#Preview("전체 - 5개 할일 + 2개 휴식") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, FocusItem.self, BreakSession.self, configurations: config)
    let context = container.mainContext
    
    let session = PreviewReportData.createMockSession(in: context)
    try? context.save()
    
    let mainVM = MainViewModel(context: context)
    
    return ReportView(sessionID: session.persistentModelID)
        .environmentObject(MainCoordinator.shared)
        .environmentObject(mainVM)
        .modelContainer(container)
}

// MARK: - 휴식 많음 프리뷰
#Preview("휴식 많음 - 6개 할일 + 4개 휴식") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, FocusItem.self, BreakSession.self, configurations: config)
    let context = container.mainContext
    
    let session = PreviewReportData.createManyBreaksSession(in: context)
    try? context.save()
    
    let mainVM = MainViewModel(context: context)
    
    return ReportView(sessionID: session.persistentModelID)
        .environmentObject(MainCoordinator.shared)
        .environmentObject(mainVM)
        .modelContainer(container)
}

// MARK: - Preview Data Factory for Report
enum PreviewReportData {
    
    // MARK: - 단순한 Mock Session (디버깅용)
    @MainActor
    static func createSimpleMockSession(in context: ModelContext) -> FocusSession {
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료된 할 일 2개
        let completedItem1 = FocusItem(
            title: "알고리즘 문제 풀기",
            setSeconds: 1800,
            elapsedSeconds: 2100,
            isCompleted: true,
            order: 0
        )
        context.insert(completedItem1)
        session.items.append(completedItem1)
        
        let completedItem2 = FocusItem(
            title: "프로젝트 문서 작성",
            setSeconds: 1200,
            elapsedSeconds: 900,
            isCompleted: true,
            order: 1
        )
        context.insert(completedItem2)
        session.items.append(completedItem2)
        
        // 미완료 할 일 2개
        let incompletedItem1 = FocusItem(
            title: "운동하기",
            setSeconds: 1800,
            elapsedSeconds: 300,
            isCompleted: false,
            order: 2
        )
        context.insert(incompletedItem1)
        session.items.append(incompletedItem1)
        
        let incompletedItem2 = FocusItem(
            title: "책 읽기",
            setSeconds: 1200,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 3
        )
        context.insert(incompletedItem2)
        session.items.append(incompletedItem2)
        
        // 휴식 1개
        let breakSession = BreakSession(
            start: Date().addingTimeInterval(-2400),
            end: Date().addingTimeInterval(-2100),
            isOverdue: false
        )
        context.insert(breakSession)
        session.breaks.append(breakSession)
        
        return session
    }
    
    // MARK: - 기본 Mock Session
    @MainActor
    static func createMockSession(in context: ModelContext) -> FocusSession {
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료된 할 일 추가
        let completedItem1 = FocusItem(
            title: "알고리즘 문제 풀기",
            setSeconds: 1800,
            elapsedSeconds: 2100,
            isCompleted: true,
            order: 0
        )
        context.insert(completedItem1)
        session.items.append(completedItem1)
        
        let completedItem2 = FocusItem(
            title: "운동하기",
            setSeconds: 1200,
            elapsedSeconds: 900,
            isCompleted: true,
            order: 1
        )
        context.insert(completedItem2)
        session.items.append(completedItem2)
        
        let completedItem3 = FocusItem(
            title: "프로젝트 문서 작성",
            setSeconds: 2400,
            elapsedSeconds: 2400,
            isCompleted: true,
            order: 2
        )
        context.insert(completedItem3)
        session.items.append(completedItem3)
        
        // 미완료 할 일 추가
        let incompletedItem1 = FocusItem(
            title: "영어 공부",
            setSeconds: 1800,
            elapsedSeconds: 600,
            isCompleted: false,
            order: 3
        )
        context.insert(incompletedItem1)
        session.items.append(incompletedItem1)
        
        let incompletedItem2 = FocusItem(
            title: "책 읽기",
            setSeconds: 1200,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 4
        )
        context.insert(incompletedItem2)
        session.items.append(incompletedItem2)
        
        // 휴식 기록 추가
        let break1 = BreakSession(
            start: Date().addingTimeInterval(-2400),
            end: Date().addingTimeInterval(-2100),
            isOverdue: false
        )
        context.insert(break1)
        session.breaks.append(break1)
        
        let break2 = BreakSession(
            start: Date().addingTimeInterval(-1200),
            end: Date().addingTimeInterval(-600),
            isOverdue: false
        )
        context.insert(break2)
        session.breaks.append(break2)
        
        return session
    }
    
    // MARK: - 휴식 많은 세션
    @MainActor
    static func createManyBreaksSession(in context: ModelContext) -> FocusSession {
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-7200),
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료 항목 4개
        let completedTitles = [
            "코드 리뷰",
            "알고리즘 문제 풀기",
            "문서 작성",
            "프로젝트 기획"
        ]
        
        for (index, title) in completedTitles.enumerated() {
            let item = FocusItem(
                title: title,
                setSeconds: 1500,
                elapsedSeconds: 1500 + (index * 200),
                isCompleted: true,
                order: index
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 미완료 항목 2개
        let incompletedTitles = ["운동하기", "책 읽기"]
        
        for (index, title) in incompletedTitles.enumerated() {
            let item = FocusItem(
                title: title,
                setSeconds: 1200,
                elapsedSeconds: index == 0 ? 400 : 0,
                isCompleted: false,
                order: 4 + index
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 휴식 4개 (일반 3개, 초과 1개)
        let breaks = [
            (Date().addingTimeInterval(-6000), Date().addingTimeInterval(-5700), false),
            (Date().addingTimeInterval(-4500), Date().addingTimeInterval(-4200), false),
            (Date().addingTimeInterval(-3000), Date().addingTimeInterval(-2400), true), // 초과
            (Date().addingTimeInterval(-1200), Date().addingTimeInterval(-900), false)
        ]
        
        for breakData in breaks {
            let breakSession = BreakSession(
                start: breakData.0,
                end: breakData.1,
                isOverdue: breakData.2
            )
            context.insert(breakSession)
            session.breaks.append(breakSession)
        }
        
        return session
    }
}
#endif
