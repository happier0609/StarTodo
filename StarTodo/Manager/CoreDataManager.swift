//
//  CoreDataManager.swift
//  JPS_3
//
//  Created by ChoMinKyung on 3/22/25.
//

import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "TodoModel")
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 로드 실패: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // ✅ Preview용 CoreDataManager
    static var preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.context

        let sampleParent = TodoEntity(context: context)
        sampleParent.id = UUID()
        sampleParent.title = "레퍼런스 조사하기"
        sampleParent.isCompleted = false
        sampleParent.performedDate = Date()

        let sampleChild = TodoEntity(context: context)
        sampleChild.id = UUID()
        sampleChild.title = "미디어와 현대사회 과제하기"
        sampleChild.isCompleted = false
        sampleChild.performedDate = Date()
        sampleChild.parent = sampleParent
        sampleParent.addToChildren(sampleChild)

        do {
            try context.save()
        } catch {
            fatalError("❌ 미리보기 저장 실패: \(error)")
        }

        return manager
    }()

    // ✅ 1. 할 일 전체 목록 불러오기
    func fetchTodos() -> [TodoEntity] {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("❌ 할 일 목록 가져오기 실패: \(error)")
            return []
        }
    }

    // ✅ 2. 할 일 추가
    func addTodo(title: String, note: String, elapsedTime: Int32, setTime: Int32, parent: TodoEntity? = nil) {
        let newTodo = TodoEntity(context: context)
        newTodo.id = UUID()
        newTodo.title = title
        newTodo.note = note
        newTodo.setTime = setTime
        newTodo.elapsedTime = elapsedTime
        newTodo.performedDate = Date()

        if let parent = parent {
            newTodo.parent = parent
            parent.addToChildren(newTodo)
        }

        saveContext()
    }

    // ✅ 3. 경과 시간 업데이트
    func updateElapsedTime(todo: TodoEntity, elapsedTime: Int32) {
        todo.elapsedTime = elapsedTime
        saveContext()
    }

    // ✅ 4. 할 일 삭제
    func deleteTodo(todo: TodoEntity) {
        context.delete(todo)
        saveContext()
    }

    // ✅ 5. 저장
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ CoreData 저장 실패: \(error)")
        }
    }

    // ✅ 6. 상위 할 일만 가져오기
    func fetchTopLevelTodos() -> [TodoEntity] {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        do {
            return try context.fetch(request)
        } catch {
            print("❌ 상위 할 일 가져오기 실패: \(error)")
            return []
        }
    }

    // ✅ 7. 특정 부모의 하위 할 일 가져오기
    func fetchChildren(of parent: TodoEntity) -> [TodoEntity] {
        return (parent.children?.allObjects as? [TodoEntity]) ?? []
    }

    // ✅ 8. 할 일 완료 상태 토글
    func toggleTodoCompletion(todo: TodoEntity) {
        todo.isCompleted.toggle()
        if todo.isCompleted {
            if let children = todo.children?.allObjects as? [TodoEntity] {
                for child in children {
                    child.isCompleted = true
                }
            }
        }
        saveContext()
    }

    // ✅ 9. 완료/미완료 항목 가져오기
    func fetchCompletedTodos() -> [TodoEntity] {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true")
        do {
            return try context.fetch(request)
        } catch {
            print("❌ 완료된 할 일 가져오기 실패: \(error)")
            return []
        }
    }

    func fetchIncompleteTodos() -> [TodoEntity] {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == false")
        do {
            return try context.fetch(request)
        } catch {
            print("❌ 미완료 할 일 가져오기 실패: \(error)")
            return []
        }
    }

    // ✅ 10. UUID로 할 일 1개 가져오기
    func fetchTodo(by id: UUID) -> TodoEntity? {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ UUID로 할 일 가져오기 실패: \(error)")
            return nil
        }
    }
}
