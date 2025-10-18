//
//  AddListViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/1/25.
//

/// 역할: 할 일 목록 필터링 (오늘/이전), 삭제, 추가/편집 모달

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AddListViewModel: ObservableObject {

    // MARK: - 수동 관리할 부모 Todo 목록
    @Published var parents: [Todo] = []

    // MARK: - 상태
    @Published var showModal: Bool = false
    @Published var editingParent: Todo? = nil

    @Published var showAlert: Bool = false
    @Published var parentToDelete: Todo? = nil
    
    // MARK: - 완료 기준 시간 설정 (새벽 5시)
    @AppStorage("resetHour") private var resetHour: Int = 5

    // MARK: - SwiftData 관련
    
    private var context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        fetchTodos()
    }
    
    // Convenience init for cases where we need a default context
    convenience init() {
        self.init(context: defaultContext)
    }
    
    // 내부 메서드에서 context 사용을 위한 setter (필요시)
    func setContext(_ newContext: ModelContext) {
        self.context = newContext
        fetchTodos()
    }
    
    // MARK: - Fetch 로직
    
    private func fetchTodos() {
        do {
            // 전체 할 일 Fetch
            let fd = FetchDescriptor<Todo>()
            let list = try context.fetch(fd)
            
            // 메모리 내 정렬
            let sorted = list.sorted {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted && $1.isCompleted }
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.createdAt < $1.createdAt
            }
            
            parents = sorted.filter { $0.parent == nil }
        } catch {
            print("❌ SwiftData fetch 실패:", error.localizedDescription)
            parents = []
        }
    }

    // MARK: - 오늘 할 일 / 이전 할 일 필터링
    var todayParents: [Todo] {
        filterVisibleTodos(from: parents)
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }

    var previousParents: [Todo] {
        filterVisibleTodos(from: parents)
            .filter { !Calendar.current.isDateInToday($0.createdAt) }
            .sorted(by: sortingRule)
    }
    
    // MARK: - 표시 가능한 Todo 필터링
    /// 완료 기준 시간을 고려하여 표시할 Todo만 필터링
    private func filterVisibleTodos(from todos: [Todo]) -> [Todo] {
        todos.compactMap { parent in
            // 부모가 완료되었는데 표시 기간이 지났으면 제외
            guard shouldShowCompletedTodo(parent) else { return nil }
            
            // 부모가 미완료인 경우는 자식 상태와 관계없이 항상 표시
            // (자식이 모두 완료되어 숨겨져도 부모는 계속 보임)
            
            return parent
        }
    }
    
    // MARK: - 표시 가능한 자식 Todo 필터링
    /// 완료 기준 시간을 고려하여 표시할 자식 Todo만 반환
    /// - Parameter parent: 부모 Todo
    /// - Returns: 표시 가능한 자식 Todo 배열
    func getVisibleChildren(of parent: Todo) -> [Todo] {
        parent.children.filter { shouldShowCompletedTodo($0) }
    }

    /// 할 일 정렬 기준: 완료여부 → order → 생성시간
    private func sortingRule(a: Todo, b: Todo) -> Bool {
        let left = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
        let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
        return left < right
    }

    // MARK: - ✨ 부모 Todo 목록 갱신 (핵심 메서드)
    func fetchParents(with context: ModelContext) {
        do {
            // ✅ 부모 항목 전체 가져오기 (완료/미완료 모두)
            let descriptor = FetchDescriptor<Todo>(
                predicate: #Predicate { todo in
                    todo.parent == nil
                }
            )
            let fetchedTodos = try context.fetch(descriptor)
            
            print("📊 AddListViewModel fetchParents:")
            print("  전체 부모 항목: \(fetchedTodos.count)개")
            
            // ✅ 각 항목의 완료 상태 디버깅
            for todo in fetchedTodos {
                print("  🔍 \(todo.title):")
                print("     - isCompleted: \(todo.isCompleted)")
                print("     - performedDate: \(todo.performedDate?.description ?? "nil")")
                if todo.isCompleted && todo.performedDate == nil {
                    print("     ⚠️ 경고: 완료되었지만 performedDate가 없음!")
                }
            }
            
            // ✅ 표시 가능한 항목만 필터링 (리셋 기준 시간 적용)
            let visibleTodos = fetchedTodos.filter { shouldShowCompletedTodo($0) }
            
            print("  표시 가능한 항목: \(visibleTodos.count)개")
            
            // 완료/미완료 카운트
            let completedCount = visibleTodos.filter { $0.isCompleted }.count
            let incompletedCount = visibleTodos.count - completedCount
            print("  미완료: \(incompletedCount)개, 완료: \(completedCount)개")
            
            // 수동으로 정렬 적용
            parents = visibleTodos.sorted { a, b in
                // 1. 완료 여부 (미완료가 먼저)
                if a.isCompleted != b.isCompleted {
                    return !a.isCompleted && b.isCompleted
                }
                // 2. order 순서
                if a.order != b.order {
                    return a.order < b.order
                }
                // 3. 생성 시간
                return a.createdAt < b.createdAt
            }
            
            // 디버깅: 최종 표시 항목
            print("\n  📋 최종 표시 항목:")
            for parent in parents {
                let status = parent.isCompleted ? "✅ 완료" : "⏳ 미완료"
                let childCount = parent.children.count
                let completedChildren = parent.children.filter { $0.isCompleted }.count
                print("  - \(status) \(parent.title) (자식: \(completedChildren)/\(childCount) 완료)")
            }
            
        } catch {
            print("❌ Todo fetch 실패: \(error.localizedDescription)")
            parents = []
        }
    }

    // MARK: - 완료 할 일 표시 여부 판단
    /// 완료된 할 일이 UI에 표시되어야 하는지 판단
    /// - Parameter todo: 확인할 Todo 객체
    /// - Returns: UI에 표시할 경우 true
    private func shouldShowCompletedTodo(_ todo: Todo) -> Bool {
        // 미완료 항목은 항상 표시
        guard todo.isCompleted else {
            return true
        }
        
        print("  🔍 완료 항목 체크: \(todo.title)")
        
        // 완료 날짜가 없으면 표시하지 않음
        guard let performedDate = todo.performedDate else {
            print("     ⚠️ performedDate 없음 → 숨김")
            return false
        }
        
        // ✅ 다음 리셋 시간 계산 (미래의 새벽 5시)
        let nextResetTime = calculateNextResetTime(from: performedDate)
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        
        print("     완료 시각: \(formatter.string(from: performedDate))")
        print("     리셋 시각: \(formatter.string(from: nextResetTime))")
        print("     현재 시각: \(formatter.string(from: now))")
        
        // 현재 시간이 다음 리셋 시간 이전이면 표시
        let shouldShow = now < nextResetTime
        print("     결과: \(shouldShow ? "표시" : "숨김")")
        
        return shouldShow
    }

    //// 완료 시각으로부터 다음 리셋 시간 계산 (미래의 새벽 5시)
    private func calculateNextResetTime(from performedDate: Date) -> Date {
        let calendar = Calendar.current
        
        // 완료 당일의 리셋 시간 계산
        var sameDayResetComponents = calendar.dateComponents([.year, .month, .day], from: performedDate)
        sameDayResetComponents.hour = resetHour
        sameDayResetComponents.minute = 0
        sameDayResetComponents.second = 0
        
        guard let sameDayResetTime = calendar.date(from: sameDayResetComponents) else {
            return performedDate
        }
        
        // 완료 시각이 당일 리셋 시간 이전이면 당일 리셋 시간 사용
        if performedDate < sameDayResetTime {
            return sameDayResetTime
        }
        
        // 완료 시각이 당일 리셋 시간 이후면 다음날 리셋 시간 사용
        guard let nextDayResetTime = calendar.date(byAdding: .day, value: 1, to: sameDayResetTime) else {
            return performedDate
        }
        
        return nextDayResetTime
    }

    // MARK: - 부모 할 일 fetch (async 버전 - 필요시 사용)
    func fetchParentTodos(context: ModelContext) async throws -> [Todo] {
        let descriptor = FetchDescriptor<Todo>(
            predicate: #Predicate { todo in
                todo.parent == nil
            }
        )
        let fetchedTodos = try context.fetch(descriptor)
        
        return fetchedTodos.sorted { a, b in
            if a.isCompleted != b.isCompleted {
                return !a.isCompleted && b.isCompleted
            }
            if a.order != b.order {
                return a.order < b.order
            }
            return a.createdAt < b.createdAt
        }
    }

    // MARK: - 삭제 경고 호출
    func showDeleteAlert(for parent: Todo) {
        parentToDelete = parent
        showAlert = true
    }

    // MARK: - 삭제 수행
    func delete(parent: Todo, in context: ModelContext) {
        // 자식 Todo들도 함께 삭제 (SwiftData의 cascade 삭제가 작동하지 않을 경우를 대비)
        for child in parent.children {
            context.delete(child)
        }
        
        // 부모 Todo 삭제
        context.delete(parent)
        
        do {
            try context.save()
            fetchParents(with: context) // 삭제 후 목록 갱신
            print("✅ Todo '\(parent.title)' 및 하위 항목 \(parent.children.count)개 삭제 완료")
        } catch {
            print("❌ 삭제 저장 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 순서 재배치
    func reorderRootTodos(from: IndexSet, to destination: Int, in context: ModelContext) {
        var items = parents.sorted { $0.order < $1.order }
        items.move(fromOffsets: from, toOffset: destination)
        for (i, t) in items.enumerated() {
            t.order = i
        }
        do {
            try context.save()
            fetchParents(with: context) // 재정렬 후 목록 갱신
        } catch {
            print("❌ 재정렬 저장 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - 모달 저장 로직 (신규 추가 또는 편집)
extension AddListViewModel {
    
    /// 부모 Todo를 저장 (추가 또는 수정)
    func saveTodo(
        editingParent: Todo?,
        title: String,
        children: [String],
        context: ModelContext
    ) {
        if let todo = editingParent {
            updateTodo(todo, with: title, children: children, context: context)
        } else {
            createTodo(with: title, children: children, context: context)
        }

        do {
            try context.save()
            fetchParents(with: context)
        } catch {
            print("❌ 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 기존 Todo 수정
    private func updateTodo(
        _ todo: Todo,
        with title: String,
        children: [String],
        context: ModelContext
    ) {
        todo.title = title

        let existingChildren = todo.children
        let existingTitles = Set(existingChildren.map(\.title))
        let newTitles = Set(children)

        // ⛔️ 기존에는 없고, 새 목록에도 없는 → 삭제 대상
        for child in existingChildren where !newTitles.contains(child.title) {
            context.delete(child)
        }

        // ✅ 새로 추가될 자식만 필터링
        let toAdd = children.filter { !existingTitles.contains($0) }
        let startOrder = (todo.children.map(\.order).max() ?? -1) + 1

        for (offset, raw) in toAdd.enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let child = Todo(
                title: trimmed,
                isCompleted: false,
                setTime: todo.setTime,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: startOrder + offset,
                parent: todo
            )
            todo.children.append(child)
        }
    }

    /// 새로운 Todo 생성
    private func createTodo(
        with title: String,
        children: [String],
        context: ModelContext
    ) {
        let nextOrder = (parents.map(\.order).max() ?? -1) + 1

        let parent = Todo(
            title: title,
            isCompleted: false,
            setTime: 25,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: nextOrder,
            parent: nil
        )

        for (i, raw) in children.enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let child = Todo(
                title: trimmed,
                isCompleted: false,
                setTime: 25,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: i,
                parent: parent
            )
            parent.children.append(child)
        }

        context.insert(parent)
    }
}

// MARK: - Todo 완료 처리
extension AddListViewModel {
    
    /// Todo의 완료 상태를 토글 (상위-하위 연동)
    /// - Parameters:
    ///   - todo: 완료 상태를 변경할 Todo
    ///   - context: SwiftData ModelContext
    func toggleTodoCompletion(_ todo: Todo, context: ModelContext) {
        do {
            if todo.isCompleted {
                // ✅ 완료 취소
                try todo.markAsIncomplete(context: context)
                
                // 부모가 있고, 부모가 완료 상태라면 부모도 미완료로
                if let parent = todo.parent, parent.isCompleted {
                    try parent.markAsIncomplete(context: context)
                    print("  → 자식 미완료로 부모도 미완료 처리: \(parent.title)")
                }
            } else {
                // ✅ 완료 처리
                try todo.markAsCompleted(context: context)
                
                // 부모인 경우: 모든 자식도 완료 처리
                if !todo.children.isEmpty {
                    for child in todo.children where !child.isCompleted {
                        try child.markAsCompleted(context: context)
                        print("  → 부모 완료로 자식도 완료 처리: \(child.title)")
                    }
                }
                
                // 자식인 경우: 모든 형제가 완료되었는지 확인
                if let parent = todo.parent {
                    let allSiblingsCompleted = parent.children.allSatisfy { $0.isCompleted }
                    if allSiblingsCompleted && !parent.isCompleted {
                        try parent.markAsCompleted(context: context)
                        print("  → 모든 자식 완료로 부모도 완료 처리: \(parent.title)")
                    }
                }
            }
            
            print("🔄 AddListView에서 완료 상태 토글: \(todo.title)")
            print("  - 완료 여부: \(todo.isCompleted)")
            print("  - 완료 시각: \(todo.performedDate?.description ?? "nil")")
            
            // ✅ 목록 새로고침
            fetchParents(with: context)
            
        } catch {
            print("❌ 완료 상태 토글 실패: \(error.localizedDescription)")
        }
    }
}
