//
//  Todo.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation
import SwiftData

/// 앱 전반의 '할 일' 엔티티 (상·하위 구조/정렬/완료 여부 보유)
@Model
final class Todo {
    @Attribute(.unique) var id: UUID              // Focus/Report 등 외부에서 식별용
    var title: String
    var isCompleted: Bool
    var setMinutes: Int                           // 사용자가 설정한 분(min)
    var createdAt: Date
    var order: Int                                // 같은 부모 안에서의 정렬용

    // 계층 구조
    var parent: Todo?                             // 상위
    @Relationship(deleteRule: .cascade, inverse: \Todo.parent)
    var children: [Todo] = []                     // 하위

    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         setMinutes: Int = 25,
         createdAt: Date = .now,
         order: Int = 0,
         parent: Todo? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.setMinutes = setMinutes
        self.createdAt = createdAt
        self.order = order
        self.parent = parent
    }
}
