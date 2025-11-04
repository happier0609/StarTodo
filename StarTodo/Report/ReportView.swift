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
    
    // FIX: 저장 중 상태 표시를 위한 변수
    @State private var isSaving = false
    
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
            
            // FIX: 완료 버튼 - 비동기 처리로 저장 완료 보장
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
            .disabled(isSaving) // 저장 중에는 버튼 비활성화
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, configurations: config)
    let viewModel = ReportViewModel(session: session, context: container.mainContext)
    
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, configurations: config)
    let viewModel = ReportViewModel(session: session, context: container.mainContext)
    
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
}
#endif
