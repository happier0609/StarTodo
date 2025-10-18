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

#if DEBUG
import SwiftUI
import SwiftData

// MARK: - 기본 프리뷰
#Preview("기본 - 완료/미완료 혼합") {
    let session = PreviewReportData.createSimpleMockSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 전체 데이터 프리뷰
#Preview("전체 - 5개 할일 + 2개 휴식") {
    let session = PreviewReportData.createMockSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 짧은 세션 프리뷰
#Preview("짧은 세션 - 15분") {
    let session = PreviewReportData.createShortSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 전체 완료 프리뷰
#Preview("전체 완료 - 모든 작업 완료") {
    let session = PreviewReportData.createAllCompletedSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 휴식 없음 프리뷰
#Preview("휴식 없음 - 논스톱 작업") {
    let session = PreviewReportData.createNoBreakSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 미완료만 있는 프리뷰
#Preview("미완료만 - 완료 항목 없음") {
    let session = PreviewReportData.createOnlyIncompletedSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 긴 세션 프리뷰
#Preview("긴 세션 - 3시간 집중") {
    let session = PreviewReportData.createLongSession()
    let viewModel = ReportViewModel(session: session)
    
    ReportView(
        viewModel: viewModel,
        onComplete: { print("완료 버튼 탭됨") }
    )
    .environmentObject(MainCoordinator.shared)
    .modelContainer(for: [
        Todo.self,
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - Preview Data Factory for Report (단순화)
enum PreviewReportData {
    
    // MARK: - 단순한 Mock Session (디버깅용)
    @MainActor
    static func createSimpleMockSession() -> FocusSession {
        // 인메모리 컨테이너 생성
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        // 세션 생성
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료된 할 일 1개만
        let completedItem = FocusItem(
            title: "알고리즘 문제 풀기",
            setSeconds: 1800,
            elapsedSeconds: 2100,
            isCompleted: true,
            order: 0
        )
        context.insert(completedItem)
        session.items.append(completedItem)
        
        // 미완료 할 일 1개
        let incompletedItem = FocusItem(
            title: "책 읽기",
            setSeconds: 1200,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 1
        )
        context.insert(incompletedItem)
        session.items.append(incompletedItem)
        
        // 휴식 1개
        let breakSession = BreakSession(
            start: Date().addingTimeInterval(-2400),
            end: Date().addingTimeInterval(-2100),
            isOverdue: false
        )
        context.insert(breakSession)
        session.breaks.append(breakSession)
        
        // 컨텍스트 저장 시도
        try? context.save()
        
        return session
    }
    
    // MARK: - 기본 Mock Session
    @MainActor
    static func createMockSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
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
            title: "영어 단어 암기",
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
            title: "운동하기",
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
            isOverdue: true
        )
        context.insert(break2)
        session.breaks.append(break2)
        
        try? context.save()
        
        return session
    }
    
    // MARK: - 짧은 세션
    @MainActor
    static func createShortSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-1200),
            endedAt: Date()
        )
        context.insert(session)
        
        let item = FocusItem(
            title: "짧은 작업",
            setSeconds: 600,
            elapsedSeconds: 900,
            isCompleted: true,
            order: 0
        )
        context.insert(item)
        session.items.append(item)
        
        try? context.save()
        
        return session
    }
    
    // MARK: - 전체 완료 세션
    @MainActor
    static func createAllCompletedSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-5400),
            endedAt: Date()
        )
        context.insert(session)
        
        for i in 0..<3 {
            let item = FocusItem(
                title: "완료된 작업 \(i + 1)",
                setSeconds: 1800,
                elapsedSeconds: 1800 + (i * 300),
                isCompleted: true,
                order: i
            )
            context.insert(item)
            session.items.append(item)
        }
        
        let breakSession = BreakSession(
            start: Date().addingTimeInterval(-3000),
            end: Date().addingTimeInterval(-2700),
            isOverdue: false
        )
        context.insert(breakSession)
        session.breaks.append(breakSession)
        
        try? context.save()
        
        return session
    }
    
    // MARK: - 휴식 없는 세션
    @MainActor
    static func createNoBreakSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date()
        )
        context.insert(session)
        
        let item1 = FocusItem(
            title: "작업 1",
            setSeconds: 1800,
            elapsedSeconds: 2100,
            isCompleted: true,
            order: 0
        )
        context.insert(item1)
        session.items.append(item1)
        
        let item2 = FocusItem(
            title: "작업 2",
            setSeconds: 1200,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 1
        )
        context.insert(item2)
        session.items.append(item2)
        
        try? context.save()
        
        return session
    }
    
    // MARK: - 미완료만 있는 세션
    @MainActor
    static func createOnlyIncompletedSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date()
        )
        context.insert(session)
        
        // 미완료 항목들만
        let items = [
            ("운동하기", 1800, 300),
            ("책 읽기", 1200, 0),
            ("명상하기", 900, 0)
        ]
        
        for (index, data) in items.enumerated() {
            let item = FocusItem(
                title: data.0,
                setSeconds: data.1,
                elapsedSeconds: data.2,
                isCompleted: false,
                order: index
            )
            context.insert(item)
            session.items.append(item)
        }
        
        try? context.save()
        
        return session
    }
    
    // MARK: - 긴 세션 (3시간)
    @MainActor
    static func createLongSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-10800), // 3시간 전
            endedAt: Date()
        )
        context.insert(session)
        
        // 6개의 작업
        let tasks = [
            ("프로젝트 기획", 1800, 2100, true),
            ("코드 리뷰", 1200, 1200, true),
            ("문서 작성", 2400, 2700, true),
            ("팀 미팅 준비", 900, 1200, true),
            ("이메일 처리", 600, 300, true),
            ("독서", 1800, 0, false)
        ]
        
        for (index, data) in tasks.enumerated() {
            let item = FocusItem(
                title: data.0,
                setSeconds: data.1,
                elapsedSeconds: data.2,
                isCompleted: data.3,
                order: index
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 3번의 휴식
        let breaks = [
            (Date().addingTimeInterval(-8400), Date().addingTimeInterval(-8100), false),
            (Date().addingTimeInterval(-5400), Date().addingTimeInterval(-5100), false),
            (Date().addingTimeInterval(-2400), Date().addingTimeInterval(-1800), true)
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
        
        try? context.save()
        
        return session
    }
}
#endif
