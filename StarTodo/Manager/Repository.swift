//
//  Repository.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftData
import Foundation

@MainActor
protocol TodoManaging: AnyObject {
    func nextRootOrder() throws -> Int
    func createParent(title: String, childTitles: [String], defaultMinutes: Int) throws
    func updateParent(_ parent: Todo, newTitle: String, newChildren: [String], defaultMinutes: Int) throws
    func delete(_ todo: Todo) throws
    func save() throws
    
    // 선택: 뷰에서 바로 쓰기 좋은 헬퍼
    func fetchRootParents() throws -> [Todo]
}

@MainActor
final class TodoRepository: ObservableObject, TodoManaging {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    
    func nextRootOrder() throws -> Int {
        let fd = FetchDescriptor<Todo>(predicate: #Predicate { $0.parent == nil })
        let maxOrder = try context.fetch(fd).map(\.order).max() ?? -1
        return maxOrder + 1
    }
    
    func createParent(title: String, childTitles: [String], defaultMinutes: Int) throws {
        let parent = Todo(title: title, setTime: defaultMinutes, order: try nextRootOrder())
        for (idx, raw) in childTitles.enumerated() {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            parent.children.append(
                Todo(title: t, setTime: defaultMinutes, order: idx, parent: parent)
            )
        }
        context.insert(parent)
        try save()
    }
    
    func updateParent(_ parent: Todo, newTitle: String, newChildren: [String], defaultMinutes: Int) throws {
        parent.title = newTitle
        let existing = parent.children
        let existingTitles = Set(existing.map(\.title))
        let newTitleSet    = Set(newChildren)
        
        for c in existing where !newTitleSet.contains(c.title) { context.delete(c) }
        
        let toAdd = newChildren.filter { !existingTitles.contains($0) }
        let startOrder = (parent.children.map(\.order).max() ?? -1) + 1
        for (offset, raw) in toAdd.enumerated() {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            parent.children.append(
                Todo(title: t, setTime: defaultMinutes, order: startOrder + offset, parent: parent)
            )
        }
        try save()
    }
    
    func delete(_ todo: Todo) throws {
        context.delete(todo)
        try save()
    }
    
    func save() throws { try context.save() }
}
