//
//  FocusTimerView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusTimerView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        VStack(spacing: 20) {
            // ⬇️ 상단 영역: 휴식 중이면 버블, 아니면 기존 헤더
            if viewModel.isBreakActive {
                BreakInfoBubble()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let current = viewModel.currentTodo {
                FocusTimerHeaderView(
                    title: current.title,
                    isCompleted: viewModel.isCurrentTodoCompleted,
                    labelText: viewModel.headerLabelText,   // ← 뷰모델 계산 프로퍼티
                    timeText: viewModel.headerTimeText,     // ← 뷰모델 계산 프로퍼티
                    onComplete: {
                        viewModel.completeCurrentTodo()
                    }
                )
            } else {
                Text("진행할 할 일이 없습니다.")
                    .foregroundColor(Color("Cool300"))
            }

            // 원형 타이머: 휴식/집중 공용 표시 값 사용
            CircularTimerView(
                setTime: viewModel.displaySetMinutes,
                elapsedTime: viewModel.displayElapsedSeconds
            )
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isBreakActive)
        // 120분 완료 알림은 목록 탭에서도 보이도록 FocusModeView에서 띄움
    }
}

// MARK: - Preview Helpers
#if DEBUG
import SwiftData

@MainActor
private func createFocusTimerPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(
        for: Todo.self, FocusSession.self, FocusItem.self, BreakSession.self,
        configurations: config
    ) else {
        fatalError("⚠️ Failed to create focus timer preview container")
    }
    return container
}

@MainActor
private func createTimerMockTodos(context: ModelContext) -> [(UUID, Int)] {
    let todo1 = Todo(title: "프로젝트 기획서 작성", setTime: 45, order: 0)
    let todo2 = Todo(title: "코드 리뷰 진행", setTime: 30, order: 1)
    let todo3 = Todo(title: "시간 설정 없는 작업", setTime: 0, order: 2)
    
    [todo1, todo2, todo3].forEach { context.insert($0) }
    try? context.save()
    
    return [
        (todo1.id, 45),
        (todo2.id, 30),
        (todo3.id, 0)  // 시간 설정 없음
    ]
}

@MainActor
private func createTimerViewModel(
    context: ModelContext,
    todoPairs: [(UUID, Int)],
    currentIndex: Int = 0,
    elapsedSeconds: Int = 0,
    isBreak: Bool = false,
    breakMinutes: Int = 10,
    simulateBreakProgress: Int = 0
) -> FocusModeViewModel {
    let store = SwiftDataSessionStore(context: context)
    let viewModel = FocusModeViewModel(todoIDPairs: todoPairs, context: context, store: store)
    
    viewModel.currentIndex = currentIndex
    
    if viewModel.todos.indices.contains(currentIndex) {
        let todoID = viewModel.todos[currentIndex].id
        viewModel.todoElapsed[todoID] = elapsedSeconds
    }
    
    if isBreak {
        viewModel.breakPickedMinutes = breakMinutes
        viewModel.startBreak()
        
        // 휴식 진행 상황 시뮬레이션
        if simulateBreakProgress > 0 {
            // breakElapsed를 직접 수정할 수 없으므로
            // 타이머 틱을 시뮬레이션
            for _ in 0..<simulateBreakProgress {
                // private 메서드를 호출할 수 없으므로
                // 프리뷰에서는 isBreakActive만 true로 설정
            }
        }
    }
    
    return viewModel
}

// MARK: - Previews
#Preview("FocusTimerView - Just Started") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 30
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

#Preview("FocusTimerView - Mid Progress") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 1350  // 22분 30초 경과 (45분 중)
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("FocusTimerView - Almost Done") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 2640  // 44분 경과 (45분 중 1분 남음)
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

// NEW: 60분 초과 프리뷰
#Preview("FocusTimerView - Over 60min") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 4200  // 70분 경과 (외부 원 10분 진행)
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

// NEW: 거의 120분 도달 프리뷰
#Preview("FocusTimerView - Almost 120min") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 7140  // 119분 경과 (120분 중 1분 남음)
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

#Preview("FocusTimerView - Break Mode") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 1200,
        isBreak: true,
        breakMinutes: 10
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

#Preview("FocusTimerView - Break Almost Over") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedSeconds: 1200,
        isBreak: true,
        breakMinutes: 10
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

#Preview("FocusTimerView - No Time Set") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 2,  // 시간 설정 없는 할 일
        elapsedSeconds: 300
    )
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}

#Preview("FocusTimerView - Second Task") {
    let container = createFocusTimerPreviewContainer()
    let context = container.mainContext
    let todoPairs = createTimerMockTodos(context: context)
    
    let viewModel = createTimerViewModel(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 1,  // 두 번째 할 일
        elapsedSeconds: 600  // 10분 경과
    )
    
    // 첫 번째 할 일은 완료 처리
    if viewModel.todos.indices.contains(0) {
        viewModel.todos[0].isCompleted = true
    }
    
    return FocusTimerView(viewModel: viewModel)
        .modelContainer(container)
        .background(Color("BgDark"))
}
#endif
