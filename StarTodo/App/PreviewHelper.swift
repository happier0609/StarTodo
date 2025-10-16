//
//  PreviewHelper.swift
//  StarTodo
//
//  Created by 조민경 on 10/15/25.
//

#if DEBUG
import SwiftUI
import SwiftData

// MARK: - Preview Data Factory
enum PreviewData {
    
    // MARK: - Sample Todos
    static func makeSampleTodos() -> [Todo] {
        [
            Todo(
                title: "프로젝트 기획서 작성",
                isCompleted: false,
                setTime: 25,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 0,
                parent: nil
            ),
            Todo(
                title: "디자인 시안 검토",
                isCompleted: false,
                setTime: 15,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 1,
                parent: nil
            ),
            Todo(
                title: "이메일 답장",
                isCompleted: false,
                setTime: 10,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 2,
                parent: nil
            ),
            Todo(
                title: "회의 자료 준비",
                isCompleted: false,
                setTime: 30,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 3,
                parent: nil
            )
        ]
    }
    
    // MARK: - Hierarchical Todos
    static func makeTodosWithHierarchy() -> [Todo] {
        let parent = Todo(
            title: "A프로젝트: SNS 캠페인",
            isCompleted: false,
            setTime: 60,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 0,
            parent: nil
        )
        
        let child1 = Todo(
            title: "메인 이미지 디자인",
            isCompleted: false,
            setTime: 30,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 0,
            parent: parent
        )
        
        let child2 = Todo(
            title: "카피라이팅 작성",
            isCompleted: false,
            setTime: 20,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 1,
            parent: parent
        )
        
        let child3 = Todo(
            title: "해시태그 리서치",
            isCompleted: false,
            setTime: 15,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 2,
            parent: parent
        )
        
        parent.children = [child1, child2, child3]
        
        return [parent, child1, child2, child3]
    }
    
    // MARK: - Mixed Status Todos
    static func makeMixedStatusTodos() -> [Todo] {
        [
            Todo(
                title: "완료된 작업",
                isCompleted: true,
                setTime: 25,
                elapsedTime: 25,
                createdAt: Date().addingTimeInterval(-86400),
                performedDate: Date().addingTimeInterval(-3600),
                order: 0,
                parent: nil
            ),
            Todo(
                title: "진행중인 작업",
                isCompleted: false,
                setTime: 30,
                elapsedTime: 10,
                createdAt: .now,
                performedDate: nil,
                order: 1,
                parent: nil
            ),
            Todo(
                title: "미시작 작업",
                isCompleted: false,
                setTime: 20,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 2,
                parent: nil
            )
        ]
    }
}

// MARK: - ViewModel Factory
enum PreviewViewModelFactory {
    
    // MARK: - AddListViewModel
//    static func makeAddListViewModel() -> AddListViewModel {
//        let context = makePreviewContext()
//        let vm = AddListViewModel(context: context)
//        // 샘플 데이터로 초기화
//        vm.parents = PreviewData.makeSampleTodos()
//        return vm
//    }
    
    // MARK: - TimerSettingViewModel
    static func makeTimerSettingViewModel(
        selectedCount: Int = 3,
        withHierarchy: Bool = false
    ) -> TimerSettingViewModel {
        let todos = withHierarchy ?
            PreviewData.makeTodosWithHierarchy() :
            PreviewData.makeSampleTodos()
        
        let selectedIDs = Array(todos.prefix(selectedCount)).map { $0.id }
        
        return TimerSettingViewModel(
            selectedTodoIDs: selectedIDs,
            allTodos: todos
        )
    }
    
    // MARK: - FocusSettingViewModel
    @MainActor
    static func makeFocusSettingViewModel(withHierarchy: Bool = false) -> FocusSettingViewModel {
        let vm = FocusSettingViewModel()
        let todos = withHierarchy
            ? PreviewData.makeTodosWithHierarchy()
            : PreviewData.makeSampleTodos()
        vm.loadFrom(todos)
        return vm
    }
    
    // MARK: - Helper
    @MainActor private static func makePreviewContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Todo.self,
            FocusSession.self,
            FocusItem.self,
            BreakSession.self,
            configurations: config
        )
        return container.mainContext
    }
}

// MARK: - Preview Wrapper
struct PreviewWrapper<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(MainCoordinator.shared)
            .modelContainer(for: Todo.self, inMemory: true)
    }
}

// MARK: - Preview Extensions
extension View {
    /// Preview에서 필요한 환경 객체들을 자동으로 주입
    func previewSetup() -> some View {
        PreviewWrapper {
            self
        }
    }
}
#endif
