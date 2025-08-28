//
//  MainViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftData
import SwiftUI

// 앱 페이지 상태
enum AppPage {
    case todoList
    case focusSetting
    case focusTimerSetting
    case report
}

@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Published (UI 바인딩)
    @Published var todoEntities: [Todo] = []            // 전체 할 일
    @Published var selectedTodos: [Todo] = []           // FocusSetting에서 선택된 항목
    @Published var timeSettings: [UUID: Int] = [:]      // id별 설정 분(뷰 전용 캐시)
    @Published var selectedIDs: [UUID] = []             // 선택된 id
    @Published var todoItems: [Todo] = []               // 루트(상위만)
    @Published var selectedTodoTimes: [UUID: Int] = [:] // (사용 중이면 유지)
    @Published var selectedFocusTodos: [Todo] = []      // 집중모드로 넘길 최종 목록
    @Published var currentPage: AppPage = .todoList

    // 완료 판정 리셋 기준 시각 (ex. 새벽 5시)
    @AppStorage("resetHour") var resetHour: Int = 5

    // MARK: - SwiftData
    private let context: ModelContext
    init(context: ModelContext) {
        self.context = context
        fetchTodos()
    }

    // MARK: - Derived
    var incompleteTodos: [Todo] { todoEntities.filter { !$0.isCompleted } }
    var uncompletedTodos: [Todo] { incompleteTodos }

    var completedTodos: [Todo] {
        todoEntities.filter {
            $0.isCompleted && (($0.performedDate ?? .distantPast) >= completionResetTime)
        }
    }

    var todayTodos: [Todo] {
        todoEntities.filter {
            Calendar.current.isDateInToday($0.createdAt) && $0.parent == nil
        }
    }

    var previousTodos: [Todo] {
        todoEntities.filter {
            !Calendar.current.isDateInToday($0.createdAt) && $0.parent == nil
        }
    }

    /// 완료 리셋 기준 시각 (오늘 날짜 + resetHour)
    var completionResetTime: Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comp.hour = resetHour
        return Calendar.current.date(from: comp) ?? .now
    }

    // MARK: - Fetch
    func fetchTodos() {
        do {
            // 1) 정렬/필터 없이 전부 가져오기
            let fd = FetchDescriptor<Todo>()              // ← sortBy, predicate 없음
            var list = try context.fetch(fd)

            // 2) 메모리에서 정렬 (미완료 우선 → order → createdAt)
            list.sort {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted && $1.isCompleted }
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.createdAt < $1.createdAt
            }

            // 3) 상태 갱신
            todoEntities = list
            todoItems = list.filter { $0.parent == nil }
        } catch {
            print("❌ SwiftData fetch 실패:", error.localizedDescription)
            todoEntities = []; todoItems = []
        }
    }

    // MARK: - CRUD

    /// 상위 할 일 + 자식들 생성
    func addParentTodo(with title: String, childTitles: [String], defaultMinutes: Int = 25) {
        // 다음 루트 order
        let nextOrder = (todoItems.map(\.order).max() ?? -1) + 1

        let parent = Todo(title: title,
                          isCompleted: false,
                          setTime: defaultMinutes,
                          elapsedTime: 0,
                          createdAt: .now,
                          performedDate: nil,
                          order: nextOrder,
                          parent: nil)

        for (idx, raw) in childTitles.enumerated() {
            let ct = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !ct.isEmpty else { continue }
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

    /// 상위 할 일 편집(자식 동기화: 삭제/추가)
    func updateParentTodo(_ todo: Todo, newTitle: String, newChildren: [String]) {
        todo.title = newTitle

        let existing = todo.children
        let existingTitles = Set(existing.map(\.title))
        let newTitleSet    = Set(newChildren)

        // 삭제될 자식
        for child in existing where !newTitleSet.contains(child.title) {
            context.delete(child)
        }

        // 새로 추가될 자식
        let toAdd = newChildren.filter { !existingTitles.contains($0) }
        let startOrder = (todo.children.map(\.order).max() ?? -1) + 1
        for (offset, raw) in toAdd.enumerated() {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            let child = Todo(title: t,
                             isCompleted: false,
                             setTime: todo.setTime,   // 부모 기본값을 물려줌
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

    /// 루트(부모 == nil) 항목의 순서를 재배치 (List.onMove 에서 사용)
    func reorderRootTodos(from: IndexSet, to destination: Int) {
        // 현재 루트들만 정렬 기준으로 복사
        var items = todoItems.sorted { $0.order < $1.order }
        items.move(fromOffsets: from, toOffset: destination)
        // 새 order를 0부터 다시 매겨주기
        for (idx, t) in items.enumerated() { t.order = idx }
        saveContext()
    }

    // MARK: - 선택 (FocusSetting)

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
            // 중복 제거 후 합침
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

    /// UI에 보여줄 설정 분 (임시 캐시 → 없으면 모델의 setTime 사용)
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
            // 저장 후 다시 fetch 해서 메모리/정렬 동기화
            fetchTodos()
        } catch {
            print("❌ SwiftData save 실패:", error.localizedDescription)
        }
    }
}
