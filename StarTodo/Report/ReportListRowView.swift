//
//  ReportListRowView.swift
//  StarTodo
//
//  Created by 조민경 on 9/24/25.
//

import SwiftUI

// 완료, 미완료, 휴식
enum ReportRowType {
    case completed(ReportItem)
    case incompleted(ReportItem)
    case breakSession(BreakSession)
}

struct ReportListRowView: View {
    let type: ReportRowType
    let viewModel: ReportViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 아이콘
            icon
                .frame(width: 20, height: 20)

            // 타이틀
            Text(title)
                .typo(.textMDRegular)
                .foregroundColor(titleColor)
            
            Spacer()

            // 서브타이틀 (시간 정보)
            if let subtitle = subtitle {
                Text(subtitle)
                    .typo(.textSMEmphasized)
                    .foregroundColor(subtitleColor)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - 아이콘
    
    private var icon: some View {
        Group {
            switch type {
            case .completed:
                // 완료: 채워진 흰색 원 + 그림자
                Circle()
                    .fill(Color("App.White"))
                    .shadow(color: Color("App.White").opacity(0.8), radius: 6)

            case .incompleted:
                // 미완료: 빈 원 (테두리만)
                Circle()
                    .stroke(Color("Cool100"), lineWidth: 2)

            case .breakSession:
                // 휴식: 빈 공간
                Circle()
                    .fill(Color.clear)
            }
        }
    }

    // MARK: - 타이틀
    
    private var title: String {
        switch type {
        case .completed(let todo), .incompleted(let todo):
            return todo.title
        case .breakSession:
            return "휴식"
        }
    }

    private var titleColor: Color {
        switch type {
        case .completed:
            return Color("BgLight")
        case .incompleted:
            return Color("Cool100")
        case .breakSession:
            return Color("BgLight")
        }
    }

    // MARK: - 서브타이틀 (시간 정보)
    
    private var subtitle: String? {
        switch type {
        case .completed(let todo):
            return viewModel.timeDescription(for: todo)
        case .incompleted:
            return nil
        case .breakSession(let session):
            return viewModel.breakDescription(for: session)
        }
    }

    private var subtitleColor: Color {
        switch type {
        case .breakSession(let session):
            return session.isOverdue ? Color("Warning200") : Color("Info200")
        default:
            return Color("Info200")
        }
    }
}

// MARK: - Preview

#if DEBUG
import SwiftUI
import SwiftData

// MARK: - 완료 항목 프리뷰
#Preview("완료 항목") {
    let session = PreviewReportRowData.createBasicSession()
    let context = PreviewReportRowData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    VStack(spacing: 0) {
        ReportListRowView(
            type: .completed(viewModel.completedTodos[0]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        ReportListRowView(
            type: .completed(viewModel.completedTodos[1]),
            viewModel: viewModel
        )
    }
    .padding()
    .background(Color("Cool1000"))
}

// MARK: - 미완료 항목 프리뷰
#Preview("미완료 항목") {
    let session = PreviewReportRowData.createBasicSession()
    let context = PreviewReportRowData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    VStack(spacing: 0) {
        ReportListRowView(
            type: .incompleted(viewModel.incompletedTodos[0]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        ReportListRowView(
            type: .incompleted(viewModel.incompletedTodos[1]),
            viewModel: viewModel
        )
    }
    .padding()
    .background(Color("Cool1000"))
}

// MARK: - 휴식 항목 프리뷰
#Preview("휴식 항목") {
    let session = PreviewReportRowData.createBasicSession()
    let context = PreviewReportRowData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    VStack(spacing: 0) {
        ReportListRowView(
            type: .breakSession(session.breaks[0]),
            viewModel: viewModel
        )
    }
    .padding()
    .background(Color("Cool1000"))
}

// MARK: - 전체 혼합 프리뷰
#Preview("전체 혼합") {
    let session = PreviewReportRowData.createBasicSession()
    let context = PreviewReportRowData.getContext()
    let viewModel = ReportViewModel(session: session, context: context)
    
    VStack(spacing: 0) {
        // 완료 항목
        ReportListRowView(
            type: .completed(viewModel.completedTodos[0]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        // 휴식
        ReportListRowView(
            type: .breakSession(session.breaks[0]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        // 완료 항목
        ReportListRowView(
            type: .completed(viewModel.completedTodos[1]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        // 미완료 항목
        ReportListRowView(
            type: .incompleted(viewModel.incompletedTodos[0]),
            viewModel: viewModel
        )
        
        Divider()
            .background(Color("Cool100").opacity(0.3))
        
        ReportListRowView(
            type: .incompleted(viewModel.incompletedTodos[1]),
            viewModel: viewModel
        )
    }
    .padding()
    .background(Color("Cool1000"))
}

// MARK: - Preview Data Factory
enum PreviewReportRowData {
    
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
}
#endif
