//
//  FocusListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusListView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        // 화면에 보이는 순서(정렬 결과)와 viewModel.todos의 순서가 다를 수 있으므로
        // 인덱스가 아니라 id로 선택/완료를 처리
        let sortedTodos = viewModel.sortedTodosForListView

        return VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(sortedTodos, id: \.id) { todo in
                        let isCurrent = todo.id == viewModel.currentTodo?.id

                        FocusListRowView(
                            title: todo.title,
                            isCompleted: todo.isCompleted,
                            isCurrent: isCurrent,
                            onComplete: {
                                viewModel.markTodoAsCompleted(id: todo.id)
                            }
                        )
                        .onTapGesture {
                            viewModel.selectTodo(id: todo.id)
                        }
                    }
                }
                .background(                      // ⬅️ 배경은 유지
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color("Cool1000"))
                )
                .mask(                            // ⬅️ 이 줄 추가: 자식까지 둥글게 클리핑
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .padding(.horizontal)
            }
        }
    }
}


// MARK: - Preview Helpers
#if DEBUG
import SwiftData

@MainActor
private func createFocusPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(
        for: Todo.self, FocusSession.self, FocusItem.self, BreakSession.self,
        configurations: config
    ) else {
        fatalError("⚠️ Failed to create focus preview container")
    }
    return container
}

@MainActor
private func createMockTodos(context: ModelContext) -> [(UUID, Int)] {
    let todo1 = Todo(title: "UI 디자인 완성하기", setTime: 30, order: 0)
    let todo2 = Todo(title: "API 연동 작업", setTime: 45, order: 1)
    let todo3 = Todo(title: "테스트 코드 작성", setTime: 25, order: 2)
    let todo4 = Todo(title: "문서 작성", setTime: 20, order: 3)
    
    [todo1, todo2, todo3, todo4].forEach { context.insert($0) }
    try? context.save()
    
    return [
        (todo1.id, 30),
        (todo2.id, 45),
        (todo3.id, 25),
        (todo4.id, 20)
    ]
}

@MainActor
private func createViewModelWithProgress(
    context: ModelContext,
    todoPairs: [(UUID, Int)],
    currentIndex: Int = 0,
    completedIndices: [Int] = [],
    elapsedTimes: [Int: Int] = [:]
) -> FocusModeViewModel {
    let store = SwiftDataSessionStore(context: context)
    let viewModel = FocusModeViewModel(todoIDPairs: todoPairs, context: context, store: store)
    
    // 현재 인덱스 설정
    viewModel.currentIndex = currentIndex
    
    // 완료된 항목 표시
    for index in completedIndices {
        if viewModel.todos.indices.contains(index) {
            viewModel.todos[index].isCompleted = true
        }
    }
    
    // 경과 시간 설정
    for (index, seconds) in elapsedTimes {
        if viewModel.todos.indices.contains(index) {
            let todoID = viewModel.todos[index].id
            viewModel.todoElapsed[todoID] = seconds
        }
    }
    
    return viewModel
}

// MARK: - Previews
#Preview("FocusListView - In Progress") {
    let container = createFocusPreviewContainer()
    let context = container.mainContext
    let todoPairs = createMockTodos(context: context)
    
    let viewModel = createViewModelWithProgress(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 1,
        elapsedTimes: [
            0: 900,  // 15분 경과
            1: 600   // 10분 경과
        ]
    )
    
    return FocusListView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("FocusListView - Some Completed") {
    let container = createFocusPreviewContainer()
    let context = container.mainContext
    let todoPairs = createMockTodos(context: context)
    
    let viewModel = createViewModelWithProgress(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 2,
        completedIndices: [0, 1],
        elapsedTimes: [
            0: 1800, // 완료
            1: 2700, // 완료
            2: 300   // 5분 경과
        ]
    )
    
    return FocusListView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("FocusListView - Almost Done") {
    let container = createFocusPreviewContainer()
    let context = container.mainContext
    let todoPairs = createMockTodos(context: context)
    
    let viewModel = createViewModelWithProgress(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 3,
        completedIndices: [0, 1, 2],
        elapsedTimes: [
            0: 1800,
            1: 2700,
            2: 1500,
            3: 600
        ]
    )
    
    return FocusListView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("FocusListView - All Completed") {
    let container = createFocusPreviewContainer()
    let context = container.mainContext
    let todoPairs = createMockTodos(context: context)
    
    let viewModel = createViewModelWithProgress(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 3,
        completedIndices: [0, 1, 2, 3],
        elapsedTimes: [
            0: 1800,
            1: 2700,
            2: 1500,
            3: 1200
        ]
    )
    
    return FocusListView(viewModel: viewModel)
        .modelContainer(container)
}

#Preview("FocusListView - Just Started") {
    let container = createFocusPreviewContainer()
    let context = container.mainContext
    let todoPairs = createMockTodos(context: context)
    
    let viewModel = createViewModelWithProgress(
        context: context,
        todoPairs: todoPairs,
        currentIndex: 0,
        elapsedTimes: [0: 30] // 30초만 경과
    )
    
    return FocusListView(viewModel: viewModel)
        .modelContainer(container)
}
#endif
