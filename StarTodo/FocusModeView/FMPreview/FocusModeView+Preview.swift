//
//  FocusModeView+Preview.swift
//  StarTodo
//
//  Created by 조민경 on 8/5/25.
//

import SwiftUI
import CoreData

// MARK: - 미리보기용 CoreDataManager
class PreviewCoreDataManager {
    static let shared = PreviewCoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "TodoModel") // ⚠️ .xcdatamodeld 이름과 일치해야 함!
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null") // 메모리에 저장
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("🧨 프리뷰용 CoreData 로딩 실패: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
}

// MARK: - 더미 TodoEntity 생성
func makePreviewTodos(context: NSManagedObjectContext) -> [TodoEntity] {
    let titles = ["영어 단어 외우기", "수학 문제 풀기", "책 읽기"]
    
    return titles.map { title in
        let todo = TodoEntity(context: context)
        todo.id = UUID()
        todo.title = title
        todo.isCompleted = false
        todo.setTime = 10
        todo.elapsedTime = 0
        todo.performedDate = Date()
        return todo
    }
}

// MARK: - ViewModel 프리뷰 인스턴스 확장
extension FocusModeViewModel {
    static func previewInstance(context: NSManagedObjectContext) -> FocusModeViewModel {
        let todos = makePreviewTodos(context: context)
        
        // 👉 UUID와 목표 시간(setTime)을 튜플로 묶어 전달
        let todoIDPairs = todos.map { ($0.id ?? UUID(), Int($0.setTime)) }
        
        let vm = FocusModeViewModel(todoIDPairs: todoIDPairs)
        
        vm.todoStates = todos.map {
            FocusTodoState(
                todo: $0,
                setTime: Int($0.setTime),
                elapsed: Int($0.elapsedTime),
                isCompleted: $0.isCompleted
            )
        }
        
        return vm
    }
}

// MARK: - SwiftUI 프리뷰
struct FocusModeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PreviewCoreDataManager.shared.context
        let viewModel = FocusModeViewModel.previewInstance(context: context)
        
        return FocusModeView(viewModel: viewModel)
            .environment(\.managedObjectContext, context)
            .previewDevice("iPad Pro (11-inch)")
    }
}
