//
//  MainViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import CoreData
import SwiftUI

// 앱 페이지 상태 관리용 enum
enum AppPage {
    case todoList
    case focusSetting
    case focusTimerSetting
    case report
}

class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var todoEntities: [TodoEntity] = []                       // 전체 할일 목록
    @Published var selectedTodos: [TodoEntity] = []                     // 선택된 할일들 (FocusSetting용)
    @Published var timeSettings: [UUID: Int] = [:]                      // 각 할일 ID별 설정된 시간
    @Published var selectedIDs: [UUID] = []                             // 선택된 할일들의 UUID 목록
    @Published var todoItems: [TodoEntity] = []                         // 상위 할일만 담은 목록 (UI용)
    @Published var selectedTodoTimes: [UUID: Int] = [:]                 // 선택된 할일들의 시간 설정 정보
    @Published var selectedFocusTodos: [TodoEntity] = []                // 집중모드에 넘겨줄 최종 선택 목록
    @Published var currentPage: AppPage = .todoList                     // 현재 앱 페이지 상태

    // @AppStorage로 resetHour 값을 유지
    @AppStorage("resetHour") var resetHour: Int = 5                     // 완료 시간 기준 시간 설정

    private let context: NSManagedObjectContext                         // CoreData context

    // MARK: - Init
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        fetchTodos()
    }

    // MARK: - Computed Properties

    var incompleteTodos: [TodoEntity] {
        todoEntities.filter { !$0.isCompleted }
    }

    var uncompletedTodos: [TodoEntity] {
        todoEntities.filter { !$0.isCompleted }
    }

    var completedTodos: [TodoEntity] {
        todoEntities.filter {
            $0.isCompleted && ($0.performedDate ?? .distantPast) >= completionResetTime
        }
    }

    var todayTodos: [TodoEntity] {
        todoEntities.filter {
            Calendar.current.isDateInToday($0.createdAt ?? Date()) && $0.parent == nil
        }
    }

    var previousTodos: [TodoEntity] {
        todoEntities.filter {
            !Calendar.current.isDateInToday($0.createdAt ?? Date()) && $0.parent == nil
        }
    }

    var completionResetTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = resetHour
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - CoreData Fetch

    func fetchTodos() {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == false")

        do {
            todoEntities = try context.fetch(request)
            fetchTodoItems()
        } catch {
            print("❌ 할 일 목록 fetch 실패: \(error)")
            todoEntities = []
        }
    }

    func fetchTodoItems() {
        // 상위 항목만 필터링하여 리스트에 저장
        todoItems = todoEntities.filter { $0.parent == nil }
    }

    // MARK: - 할 일 관리

    func addParentTodo(with title: String, childTitles: [String]) {
        let parent = TodoEntity(context: context)
        parent.title = title
        parent.id = UUID()
        parent.createdAt = Date()
        parent.isCompleted = false

        for childTitle in childTitles {
            let child = TodoEntity(context: context)
            child.title = childTitle
            child.id = UUID()
            child.createdAt = Date()
            child.isCompleted = false
            child.parent = parent
        }

        saveContext()
    }

    func updateParentTodo(_ todo: TodoEntity, newTitle: String, newChildren: [String]) {
        todo.title = newTitle
        let existingChildren = (todo.children as? Set<TodoEntity>) ?? []
        let existingTitles = existingChildren.map { $0.wrappedTitle }

        // 삭제 대상
        for child in existingChildren where !newChildren.contains(child.wrappedTitle) {
            context.delete(child)
        }

        // 추가 대상
        let titlesToAdd = newChildren.filter { !existingTitles.contains($0) }
        for title in titlesToAdd {
            let child = TodoEntity(context: context)
            child.title = title
            child.id = UUID()
            child.createdAt = Date()
            child.isCompleted = false
            child.parent = todo
        }

        saveContext()
    }

    func deleteTodo(_ todo: TodoEntity) {
        context.delete(todo)
        saveContext()
    }

    func toggleTodo(_ todo: TodoEntity) {
        todo.isCompleted.toggle()
        todo.performedDate = todo.isCompleted ? Date() : nil
        saveContext()
    }

    func saveContext() {
        do {
            try context.save()
            fetchTodos()
        } catch {
            print("❌ CoreData 저장 실패: \(error)")
        }
    }

    // MARK: - 선택 관련

    func toggleSelection(of todo: TodoEntity) {
        if let index = selectedTodos.firstIndex(where: { $0.objectID == todo.objectID }) {
            selectedTodos.remove(at: index)
        } else {
            selectedTodos.append(todo)
        }
    }

    func isSelected(_ todo: TodoEntity) -> Bool {
        selectedTodos.contains(where: { $0.objectID == todo.objectID })
    }

    func clearSelections() {
        selectedTodos.removeAll()
        selectedIDs.removeAll()
    }

    func toggleParentSelection(_ parent: TodoEntity, _ isSelected: Bool) {
        let ids = [parent.wrappedID] + parent.childrenArray.map { $0.wrappedID }
        if isSelected {
            selectedIDs.append(contentsOf: ids)
        } else {
            selectedIDs.removeAll { ids.contains($0) }
        }
    }

    func toggleChildSelection(_ child: TodoEntity, _ isSelected: Bool) {
        let id = child.wrappedID
        if isSelected {
            selectedIDs.append(id)
        } else {
            selectedIDs.removeAll { $0 == id }
        }
    }

    // MARK: - 시간 설정 관련

    func setTime(for todo: TodoEntity) -> Int {
        timeSettings[todo.id ?? UUID()] ?? 30
    }

    func updateSetTime(for todo: TodoEntity, minutes: Int) {
        guard let id = todo.id else { return }
        timeSettings[id] = minutes
    }

    // MARK: - 집중 모드 관련

    func proceedToTimeSetting(with selected: [TodoEntity]) {
        self.selectedFocusTodos = selected
        self.currentPage = .focusTimerSetting
    }

    func setFocusTarget(with todos: [TodoEntity]) {
        print("선택된 항목 수: \(todos.count)")
    }
}
