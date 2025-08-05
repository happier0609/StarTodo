//
//  PreviewCoreDataManager.swift
//  StarTodo
//
//  Created by 조민경 on 8/5/25.
//

import CoreData

class PreviewCoreDataManager {
    static let shared = PreviewCoreDataManager()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "TodoModel") // ⚠️ .xcdatamodeld 파일 이름과 같아야 함
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null") // 메모리 DB
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("프리뷰용 CoreData 로딩 실패: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }
}

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
