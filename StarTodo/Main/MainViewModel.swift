//
//  MainViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftData
import SwiftUI

// 앱 페이지 상태 관리용 enum
enum AppPage {
    case todoList
    case focusSetting
    case focusTimerSetting
    case report
}

@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Published (UI 바인딩)
    @Published var todoEntities: [Todo] = []          // 전체 할 일
    @Published var selectedTodos: [Todo] = []         // FocusSetting 선택
    @Published var timeSettings: [UUID: Int] = [:]    // 각 할 일별 설정 시간(분)
    @Published var selectedIDs: [UUID] = []           // 선택된 할 일 id
    @Published var todoItems: [Todo] = []             // 루트(상위)만
    @Published var selectedTodoTimes: [UUID: Int] = [:]
    @Published var selectedFocusTodos: [Todo] = []    // 집중모드에 전달할 최종 목록
    @Published var currentPage: AppPage = .todoList

    // 완료 카운팅 기준 시각(예: 05:00)
    @AppStorage("resetHour") var resetHour: Int = 5

    // MARK: - SwiftData
    private let context: ModelContext
    init(context: ModelContext) {
        self.context = context
        fetchTodos()
    }

    // MARK: - Computed
    var incompleteTodos: [Todo] { todoEntities.filter { !$0.isCompleted } }
    var uncompletedTodos: [Todo] { incompleteTodos }

    var completedTodos: [Todo] {
        todoEntities.filter { $0.isCompleted && (($0.performedDate ?? .distantPast) >= completionResetTime) }
    }

    var todayTodos: [Todo] {
        todoEntities.filter { Calendar.current.isDateInToday($0.createdAt) && $0.parent == nil }
    }

    var previousTodos: [Todo] {
        todoEntities.filter { !Calendar.current.isDateInToday($0.createdAt) && $0.parent == nil }
    }

    var completionResetTime: Date {
        var comp = Calendar.current.dateComponents([.year,.month,.day], from: .now)
        comp.hour = resetHour
        return Calendar.current.date(from: comp) ?? .now
    }

    // MARK: - Fetch
    func fetchTodos() {
        do {
            let fd = FetchDescriptor<Todo>(
                sortBy: [
                    .init(\Todo.isCompleted, order: .forward),
                    .init(\Todo.order,       order: .forward),
                    .init(\Todo.createdAt,   order: .forward)
                ]
            )
            todoEntities = try context.fetch(fd)
            todoItems = todoEntities.filter { $0.parent == nil }
        } catch {
            print("❌ SwiftData fetch 실패:", error.localizedDescription)
            todoEntities = []; todoItems = []
        }
    }

    // MARK: - CRUD

    /// 상위 할 일과 자식들 생성
    func addParentTodo(with title: String, childTitles: [String], defaultMinutes: Int = 25) {
        let nextOrder = (todoItems.map(\.order).max() ?? -1) + 1
        let parent = Todo(title: title,
                          isCompleted: false,
                          setTime: defaultMinutes,
                          elapsedTime: 0,
                          createdAt: .now,
                          performedDate: nil,
                          order: nextOrder,
                          parent: nil)

        for (idx, ct) in childTitles.enumerated() {
            let child = Todo(title: ct,
                             isCompleted: false,
                             setTime: defaultMinutes,
                             elapsedTime: 0,
                             createdAt: .now,
                             performedDate: nil,
                             order: idx,
                             parent: parent)
            parent.children.append(child)
        }

        context.insert(parent)
        saveContext()
    }

    /// 상위 할 일 편집(자식 동기화)
    func updateParentTodo(_ todo: Todo, newTitle: String, newChildren: [String]) {
        todo.title = newTitle

        let existing = todo.children
        let existingTitles = Set(existing.map(\.title))
        let newSet = Set(newChildren)

        // 삭제
        for child in existing where !newSet.contains(child.title) {
            context.delete(child)
        }

        // 추가
        let toAdd = newChildren.filter { !existingTitles.contains($0) }
        let startOrder = (todo.children.map(\.order).max() ?? -1) + 1
        for (offset, t) in toAdd.enumerated() {
            let child = Todo(title: t,
                             isCompleted: false,
                             setTime: todo.setTime,   // 부모와 동일 기본값
                             elapsedTime: 0,
                             createdAt: .now,
                             performedDate: nil,
                             order: startOrder + offset,
                             parent: todo)
            todo.children.append(child)
        }

        saveContext()
    }

    func deleteTodo(_ todo: Todo) {
        context.delete(todo)
        saveContext()
    }

    func toggleTodo(_ todo: Todo) {
        todo.isCompleted.toggle()
        todo.performedDate = todo.isCompleted ? .now : nil
        saveContext()
    }

    /// 같은 부모 내에서의 순서 재배치 (List.onMove 등에 사용)
    func reorderRootTodos(from: IndexSet, to destination: Int) {
        var items = todoItems.sorted { $0.order < $1.order }
        items.move(fromOffsets: from, toOffset: destination)
        for (idx, t) in items.enumerated() { t.order = idx }
        saveContext()
    }

    // MARK: - 선택(체크박스/토글) 로직

    func toggleSelection(of todo: Todo) {
        if let i = selectedTodos.firstIndex(where: { $0.id == todo.id }) {
            selectedTodos.remove(at: i)
            selectedIDs.removeAll { $0 == todo.id }
        } else {
            selectedTodos.append(todo)
            selectedIDs.append(todo.id)
        }
    }

    func isSelected(_ todo: Todo) -> Bool {
        selectedIDs.contains(todo.id)
    }

    func clearSelections() {
        selectedTodos.removeAll()
        selectedIDs.removeAll()
    }

    /// 상위 항목 선택/해제 (자식 포함)
    func toggleParentSelection(_ parent: Todo, _ select: Bool) {
        let ids = [parent.id] + parent.children.map(\.id)
        if select {
            selectedIDs = Array(Set(selectedIDs + ids))
            for t in [parent] + parent.children where !selectedTodos.contains(where: { $0.id == t.id }) {
                selectedTodos.append(t)
            }
        } else {
            selectedIDs.removeAll { ids.contains($0) }
            selectedTodos.removeAll { ids.contains($0.id) }
        }
    }

    /// 자식 개별 선택/해제
    func toggleChildSelection(_ child: Todo, _ select: Bool) {
        if select {
            if !selectedIDs.contains(child.id) { selectedIDs.append(child.id) }
            if !selectedTodos.contains(where: { $0.id == child.id }) { selectedTodos.append(child) }
        } else {
            selectedIDs.removeAll { $0 == child.id }
            selectedTodos.removeAll { $0.id == child.id }
        }
    }

    // MARK: - 시간 설정 (분)

    /// UI에 보여줄 설정 분(없으면 Todo의 setTime, 그마저도 없으면 30)
    func setTime(for todo: Todo) -> Int {
        timeSettings[todo.id] ?? todo.setTime
    }

    func updateSetTime(for todo: Todo, minutes: Int) {
        timeSettings[todo.id] = minutes
    }

    // MARK: - 집중 모드 진입

    func proceedToTimeSetting(with selected: [Todo]) {
        selectedFocusTodos = selected
        currentPage = .focusTimerSetting
    }

    func setFocusTarget(with todos: [Todo]) {
        print("선택된 항목 수: \(todos.count)")
    }

    // MARK: - Private
    private func saveContext() {
        do {
            try context.save()
            fetchTodos() // 최신 배열 갱신
        } catch {
            print("❌ SwiftData save 실패:", error.localizedDescription)
        }
    }
}
