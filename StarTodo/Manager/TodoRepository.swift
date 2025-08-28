//
//  Repository.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

//  SwiftData 기반 Todo 읽기/쓰기 레이어
//  - ViewModel/Views는 이 레포지토리만 의존하도록 하여
//    저장소 구현(SwiftData/테스트더블) 교체를 쉽게 만듭니다.

import SwiftData
import Foundation

// MARK: - Public Protocol (ViewModel/Views가 의존할 인터페이스)

@MainActor
protocol TodoManaging: AnyObject {
    // 읽기
    func fetchAll() throws -> [Todo]              // 모든 Todo (미완료 → 완료, order, createdAt 순)
    func fetchRoots() throws -> [Todo]            // 루트 Todo만 (parent == nil)
    
    // 쓰기
    func nextRootOrder() throws -> Int            // 새 루트 항목의 order 계산
    func createParent(title: String,
                      childTitles: [String],
                      defaultMinutes: Int) throws // 부모 + 자식들 한번에 생성
    func updateParent(_ parent: Todo,
                      newTitle: String,
                      newChildren: [String],
                      defaultMinutes: Int) throws // 부모/자식 동기화(추가/삭제)
    func toggle(_ todo: Todo) throws              // 완료 토글 + 완료시각 관리
    func delete(_ todo: Todo) throws              // 삭제 (자식은 cascade)
    func save() throws                            // 수동 저장
}

// MARK: - Repository Implementation

@MainActor
final class TodoRepository: ObservableObject, TodoManaging {
    
    // SwiftData의 ModelContext (DI로 주입)
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Fetch
    
    /// 모든 Todo를 불러오기
    // 정렬 없이 가져오기
    func fetchAll() throws -> [Todo] {
        let fd = FetchDescriptor<Todo>() // sortBy, predicate 없음
        let list = try context.fetch(fd)
        return sortTodosInMemory(list)
    }
    
    
    /// 루트(parent == nil) Todo만 불러오기
    func fetchRoots() throws -> [Todo] {
        let fd = FetchDescriptor<Todo>(predicate: #Predicate<Todo> { $0.parent == nil })
        let list = try context.fetch(fd)
        return sortTodosInMemory(list)
    }
    
    // ✅ 메모리 정렬(미완료 우선 → order → createdAt)
    private func sortTodosInMemory(_ list: [Todo]) -> [Todo] {
        list.sorted { a, b in
            if a.isCompleted != b.isCompleted { return !a.isCompleted && b.isCompleted } // 미완료 먼저
            if a.order != b.order { return a.order < b.order }
            return a.createdAt < b.createdAt
        }
    }
    
    // MARK: - Write
    
    /// 새 루트 항목의 order 값 계산 (기존 루트들의 max(order) + 1)
    func nextRootOrder() throws -> Int {
        let fd = FetchDescriptor<Todo>(
            predicate: #Predicate<Todo> { $0.parent == nil }
        )
        let maxOrder = try context.fetch(fd).map(\.order).max() ?? -1
        return maxOrder + 1
    }
    
    /// 부모와 자식을 한 번에 생성
    /// - title: 부모 제목
    /// - childTitles: 자식 제목 배열(빈 문자열/공백은 자동 무시)
    /// - defaultMinutes: 부모/자식 setTime 기본값(분)
    func createParent(title: String,
                      childTitles: [String],
                      defaultMinutes: Int) throws
    {
        // 부모 생성 (루트 order는 nextRootOrder로 계산)
        let parent = Todo(
            title: title,
            setTime: defaultMinutes,
            order: try nextRootOrder()
        )
        
        // 자식 생성 (부모에 append, 각 자식은 0,1,2… 순서대로 order 부여)
        for (idx, raw) in childTitles.enumerated() {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            parent.children.append(
                Todo(title: t,
                     setTime: defaultMinutes,
                     order: idx,
                     parent: parent)
            )
        }
        
        context.insert(parent) // 루트 엔티티 삽입
        try save()
    }
    
    /// 부모/자식 동기화(제목 변경, 자식 추가/삭제)
    /// - 기존에 없던 제목은 추가
    /// - 새 목록에 없는 기존 자식은 삭제(cascade 관계상 안전)
    /// - 새로 추가되는 자식의 order는 현재 children의 최대값 다음부터 부여
    func updateParent(_ parent: Todo,
                      newTitle: String,
                      newChildren: [String],
                      defaultMinutes: Int) throws
    {
        parent.title = newTitle
        
        let existingChildren = parent.children
        let existingTitles   = Set(existingChildren.map(\.title))
        let incomingTitles   = Set(newChildren)
        
        // 삭제 대상: 새 목록에 없는 기존 자식
        for child in existingChildren where !incomingTitles.contains(child.title) {
            context.delete(child)
        }
        
        // 추가 대상: 기존에 없던 제목
        let titlesToAdd = newChildren.filter { !existingTitles.contains($0) }
        
        // order 부여 시작점: 현재 남아있는 children의 max(order) + 1
        let startOrder = (parent.children.map(\.order).max() ?? -1) + 1
        
        for (offset, raw) in titlesToAdd.enumerated() {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            parent.children.append(
                Todo(title: t,
                     setTime: defaultMinutes,
                     order: startOrder + offset,
                     parent: parent)
            )
        }
        
        try save()
    }
    
    /// 완료 토글 + 완료시각(performedDate) 관리
    func toggle(_ todo: Todo) throws {
        todo.isCompleted.toggle()
        todo.performedDate = todo.isCompleted ? .now : nil
        try save()
    }
    
    /// 삭제 (부모를 지우면 children은 cascade 규칙으로 함께 삭제)
    func delete(_ todo: Todo) throws {
        context.delete(todo)
        try save()
    }
    
    /// 수동 저장 (여러 변경을 모아서 한 번에 저장할 때도 사용 가능)
    func save() throws {
        try context.save()
    }
}

// MARK: - Preview/DI Helper (선택)
// 인메모리 컨테이너로 미리보기나 샘플 구축할 때 유용
@MainActor
enum TodoRepositoryFactory {
    /// 메모리에만 저장되는 임시 컨테이너 + 레포 생성
    static func makeInMemoryRepo(seed: ((ModelContext) -> Void)? = nil) -> TodoRepository {
        let container = try! ModelContainer(
            for: Todo.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        seed?(ctx) // 시드 데이터 주입이 필요하면 여기서 추가
        return TodoRepository(context: ctx)
    }
}
