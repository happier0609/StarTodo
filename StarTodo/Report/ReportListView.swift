//
//  ReportListView.swift
//  StarTodo
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
                        
                        // 마지막 항목이 아니면 구분선 추가
                        if index < timelineItems.count - 1 {
                            Divider()
                                .background(Color("Cool100").opacity(0.3))
                        }
                    }
                }
                
                // MARK: - 미완료 섹션 (헤더 없이 바로 아이템 표시)
                if !incompletedTodos.isEmpty {
                    // 타임라인과 미완료 사이 구분선
                    if !timelineItems.isEmpty {
                        Divider()
                            .background(Color("Cool100").opacity(0.3))
                    }
                    
                    // 미완료 아이템들 (헤더 없이)
                    ForEach(Array(incompletedTodos.enumerated()), id: \.element.id) { index, todo in
                        ReportListRowView(
                            type: .incompleted(todo),
                            viewModel: viewModel
                        )
                        
                        // 마지막 항목이 아니면 구분선 추가
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

// MARK: - Preview

#if DEBUG
import SwiftUI
import SwiftData

// MARK: - 기본 프리뷰 (완료 + 미완료 혼합)
#Preview("기본 - 타임라인 + 미완료") {
    let session = PreviewReportListData.createBasicSession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 타임라인만 (완료 항목 + 휴식)
#Preview("타임라인만 - 미완료 없음") {
    let session = PreviewReportListData.createTimelineOnlySession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 미완료만
#Preview("미완료만 - 타임라인 없음") {
    let session = PreviewReportListData.createIncompletedOnlySession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 휴식 포함 타임라인
#Preview("휴식 많음 - 4개 휴식") {
    let session = PreviewReportListData.createManyBreaksSession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 긴 리스트
#Preview("긴 리스트 - 스크롤 테스트") {
    let session = PreviewReportListData.createLongListSession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - 빈 상태
#Preview("빈 상태 - 항목 없음") {
    let session = PreviewReportListData.createEmptySession()
    let context = PreviewReportListData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    ReportListView(
        timelineItems: viewModel.timelineItems,
        incompletedTodos: viewModel.incompletedTodos,
        viewModel: viewModel
    )
    .background(Color("Cool1000"))
    .modelContainer(for: [
        FocusSession.self,
        FocusItem.self,
        BreakSession.self
    ], inMemory: true)
}

// MARK: - Preview Data Factory
enum PreviewReportListData {
    
    // context를 재사용하기 위한 헬퍼 메서드
    @MainActor
    static func getContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        return ModelContext(container)
    }
    
    // MARK: - 기본 세션
    @MainActor
    static func createBasicSession() -> FocusSession {
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
        
        // 완료 2개
        let completed1 = FocusItem(
            title: "코드 리뷰",
            setSeconds: 1800,
            elapsedSeconds: 2100,
            isCompleted: true,
            order: 0
        )
        context.insert(completed1)
        session.items.append(completed1)
        
        let completed2 = FocusItem(
            title: "문서 작성",
            setSeconds: 1200,
            elapsedSeconds: 1000,
            isCompleted: true,
            order: 1
        )
        context.insert(completed2)
        session.items.append(completed2)
        
        // 미완료 2개
        let incompleted1 = FocusItem(
            title: "운동하기",
            setSeconds: 1800,
            elapsedSeconds: 300,
            isCompleted: false,
            order: 2
        )
        context.insert(incompleted1)
        session.items.append(incompleted1)
        
        let incompleted2 = FocusItem(
            title: "책 읽기",
            setSeconds: 1200,
            elapsedSeconds: 0,
            isCompleted: false,
            order: 3
        )
        context.insert(incompleted2)
        session.items.append(incompleted2)
        
        // 휴식 1개
        let breakSession = BreakSession(
            start: Date().addingTimeInterval(-2000),
            end: Date().addingTimeInterval(-1700),
            isOverdue: false
        )
        context.insert(breakSession)
        session.breaks.append(breakSession)
        
        try? context.save()
        return session
    }
    
    // MARK: - 타임라인만 (완료 + 휴식)
    @MainActor
    static func createTimelineOnlySession() -> FocusSession {
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
        
        // 완료 항목 3개
        for i in 0..<3 {
            let item = FocusItem(
                title: "완료 작업 \(i + 1)",
                setSeconds: 1800,
                elapsedSeconds: 1800 + (i * 200),
                isCompleted: true,
                order: i
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 휴식 2개
        let break1 = BreakSession(
            start: Date().addingTimeInterval(-3600),
            end: Date().addingTimeInterval(-3300),
            isOverdue: false
        )
        context.insert(break1)
        session.breaks.append(break1)
        
        let break2 = BreakSession(
            start: Date().addingTimeInterval(-1800),
            end: Date().addingTimeInterval(-1500),
            isOverdue: false
        )
        context.insert(break2)
        session.breaks.append(break2)
        
        try? context.save()
        return session
    }
    
    // MARK: - 미완료만
    @MainActor
    static func createIncompletedOnlySession() -> FocusSession {
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
        
        // 미완료 항목만 4개
        let tasks = [
            "알고리즘 문제",
            "영어 공부",
            "운동하기",
            "정리 정돈"
        ]
        
        for (index, title) in tasks.enumerated() {
            let item = FocusItem(
                title: title,
                setSeconds: 1200,
                elapsedSeconds: index == 0 ? 300 : 0,
                isCompleted: false,
                order: index
            )
            context.insert(item)
            session.items.append(item)
        }
        
        try? context.save()
        return session
    }
    
    // MARK: - 휴식 많은 세션
    @MainActor
    static func createManyBreaksSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-7200),
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료 항목 3개
        for i in 0..<3 {
            let item = FocusItem(
                title: "집중 작업 \(i + 1)",
                setSeconds: 1500,
                elapsedSeconds: 1500,
                isCompleted: true,
                order: i
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
        
        try? context.save()
        return session
    }
    
    // MARK: - 긴 리스트 (스크롤 테스트)
    @MainActor
    static func createLongListSession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-14400), // 4시간 전
            endedAt: Date()
        )
        context.insert(session)
        
        // 완료 8개
        for i in 0..<8 {
            let item = FocusItem(
                title: "작업 항목 \(i + 1)",
                setSeconds: 1200,
                elapsedSeconds: 1200 + (i * 100),
                isCompleted: true,
                order: i
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 미완료 4개
        for i in 8..<12 {
            let item = FocusItem(
                title: "미완료 항목 \(i - 7)",
                setSeconds: 1200,
                elapsedSeconds: i == 8 ? 600 : 0,
                isCompleted: false,
                order: i
            )
            context.insert(item)
            session.items.append(item)
        }
        
        // 휴식 5개
        for i in 0..<5 {
            let breakSession = BreakSession(
                start: Date().addingTimeInterval(TimeInterval(-12000 + (i * 2400))),
                end: Date().addingTimeInterval(TimeInterval(-11700 + (i * 2400))),
                isOverdue: i == 2
            )
            context.insert(breakSession)
            session.breaks.append(breakSession)
        }
        
        try? context.save()
        return session
    }
    
    // MARK: - 빈 세션
    @MainActor
    static func createEmptySession() -> FocusSession {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let session = FocusSession(
            startedAt: Date().addingTimeInterval(-600),
            endedAt: Date()
        )
        context.insert(session)
        
        try? context.save()
        return session
    }
}
#endif
