//
//  FocusModeView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FocusModeViewModel
    @State private var selectedTab: FocusTab = .timer
    @State private var todoIDPairs: [(UUID, Int)]
    @State private var isContextReady = false  // ✅ context 준비 완료 플래그
    
    // FocusTodoInput을 받아 ViewModel 초기화
    init(input: FocusTodoInput) {
        _todoIDPairs = State(initialValue: input.todoIDPairs)
        
        print("FocusModeView 초기화 시작")
        print("받은 데이터: \(input.todoIDPairs)")
        
        // ✅ 타이머를 시작하지 않는 임시 ViewModel 생성
        _viewModel = StateObject(wrappedValue: FocusModeViewModel(
            modelContext: defaultContext
        ))
    }
    
    var body: some View {
        ZStack {
            Color("BgDark")
                .ignoresSafeArea()
            
            VStack {
                FocusModeHeaderView(
                    statusText: viewModel.headerStatusText,
                    viewModel: viewModel
                )
                
                CustomSegmentedControl(selectedTab: $selectedTab)
                    .padding()
                
                switch selectedTab {
                case .timer:
                    FocusTimerView(viewModel: viewModel)
                case .list:
                    FocusListView(viewModel: viewModel)
                }
                
                FocusModeFooterView(
                    expectedEndTimeString: viewModel.expectedEndTimeString,
                    isBreakActive: viewModel.isBreakActive,
                    onRestTap: {
                        if viewModel.isBreakActive {
                            viewModel.endBreakAndResume()
                        } else {
                            viewModel.showBreakSheet = true
                        }
                    }
                )
            }
        }
        .breakTimeAlert(
            isPresented: Binding(
                get: { viewModel.showBreakSheet },
                set: { viewModel.showBreakSheet = $0 }
            ),
            minutes: Binding(
                get: { viewModel.breakPickedMinutes },
                set: { viewModel.breakPickedMinutes = $0 }
            ),
            onConfirm: {
                viewModel.startBreak()
            }
        )
        .disabled(viewModel.showBreakEndOverlay)
        .overlay {
            if viewModel.showBreakEndOverlay {
                BreakEndOverlay {
                    viewModel.endBreakAndResume()
                }
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.savedSession) {
            if let session = viewModel.savedSession {
                print("세션 완료 - ReportView로 이동: \(session.id)")
                coordinator.push(.report(sessionID: session.id))
            }
        }
        .onAppear {
            // ✅ context 준비가 안된 경우에만 실행
            guard !isContextReady else { return }
            
            print("FocusModeView 나타남")
            print("전달된 데이터: \(todoIDPairs)")
            
            // ✅ 1. 먼저 실제 ModelContext로 교체
            viewModel.modelContext = context
            viewModel.replaceStoreWithContext()
            
            // ✅ 2. 그 다음 Todos 로드 및 타이머 시작
            viewModel.reloadTodos(todoPairs: todoIDPairs)
            
            // ✅ 3. context 준비 완료 표시
            isContextReady = true
            
            print("현재 로드된 할 일 개수: \(viewModel.todos.count)")
            for (index, todo) in viewModel.todos.enumerated() {
                let setMinutes = viewModel.todoTimeSettings[todo.id] ?? 0
                let timeText = setMinutes > 0 ? "\(setMinutes)분" : "시간 없음"
                print("  \(index): \(todo.title) - \(timeText)")
            }
        }
        // Back 버튼 숨기기, 잠금 상태 만들기
        .navigationBarBackButtonHidden(true)
        .focusLocked()
    }
}

// MARK: - Preview Helpers
#if DEBUG
import SwiftData

@MainActor
private func createFocusModePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(
        for: Todo.self, FocusSession.self, FocusItem.self, BreakSession.self,
        configurations: config
    ) else {
        fatalError("⚠️ Failed to create focus mode preview container")
    }
    return container
}

@MainActor
private func createFocusModeMockTodos(context: ModelContext) -> [Todo] {
    let todos = [
        Todo(title: "프로젝트 기획서 작성", setTime: 45, order: 0),
        Todo(title: "UI 디자인 완성하기", setTime: 30, order: 1),
        Todo(title: "코드 리뷰 진행", setTime: 25, order: 2),
        Todo(title: "문서 업데이트", setTime: 20, order: 3)
    ]
    
    todos.forEach { context.insert($0) }
    try? context.save()
    
    return todos
}

@MainActor
private func createFocusTodoInput(todos: [Todo]) -> FocusTodoInput {
    let pairs = todos.map { ($0.id, $0.setTime) }
    return FocusTodoInput(todoIDPairs: pairs)
}

// MARK: - Previews
#Preview("FocusModeView - Just Started (Timer)") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    let todos = createFocusModeMockTodos(context: context)
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - In Progress (List)") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    let todos = createFocusModeMockTodos(context: context)
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Mid Session") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    let todos = createFocusModeMockTodos(context: context)
    
    // 첫 번째 할 일 완료 처리
    if let firstTodo = todos.first {
        firstTodo.isCompleted = true
    }
    try? context.save()
    
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Many Tasks") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    
    // 더 많은 할 일 생성
    let todos = (0..<8).map { index in
        let todo = Todo(
            title: "할 일 \(index + 1)",
            setTime: [25, 30, 45, 20, 35, 40, 30, 25][index],
            order: index
        )
        context.insert(todo)
        return todo
    }
    
    try? context.save()
    
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Almost Complete") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    let todos = createFocusModeMockTodos(context: context)
    
    // 처음 3개 완료 처리
    for i in 0..<3 {
        if i < todos.count {
            todos[i].isCompleted = true
        }
    }
    try? context.save()
    
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Mixed Time Settings") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    
    let todos = [
        Todo(title: "빠른 작업", setTime: 10, order: 0),
        Todo(title: "시간 설정 없음", setTime: 0, order: 1),
        Todo(title: "긴 작업", setTime: 60, order: 2),
        Todo(title: "중간 작업", setTime: 30, order: 3)
    ]
    
    todos.forEach { context.insert($0) }
    try? context.save()
    
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Single Task") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    
    let todo = Todo(title: "하나의 중요한 작업", setTime: 45, order: 0)
    context.insert(todo)
    try? context.save()
    
    let input = FocusTodoInput(todoIDPairs: [(todo.id, todo.setTime)])
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
}

#Preview("FocusModeView - Dark Mode") {
    let container = createFocusModePreviewContainer()
    let context = container.mainContext
    let todos = createFocusModeMockTodos(context: context)
    let input = createFocusTodoInput(todos: todos)
    
    return FocusModeView(input: input)
        .environmentObject(MainCoordinator.shared)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
#endif
