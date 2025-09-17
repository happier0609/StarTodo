//
//  Todo.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation
import SwiftData

/// 앱 전반의 '할 일' 엔티티 (SwiftData)
@Model
final class Todo {
    // MARK: - 기본 필드 (CoreData 스키마와 동일한 이름)
    @Attribute(.unique) var id: UUID                 // 고유 식별자
    var title: String                                // 제목
    var note: String?                                // 메모 (옵셔널)
    var isCompleted: Bool                            // 완료 여부
    var setTime: Int                                 // 계획 시간(분)  ← CoreData setTime(Int32) 대응
    var elapsedTime: Int                             // 실제 경과(초)  ← CoreData elapsedTime(Int32) 대응
    var createdAt: Date                              // 생성일
    var performedDate: Date?                         // 완료 시각(완료 취소 시 nil)
    var order: Int                                   // 같은 부모 내 정렬
    
    // MARK: - 계층 구조
    var parent: Todo?                                // 상위
    @Relationship(deleteRule: .cascade, inverse: \Todo.parent)
    var children: [Todo] = []                        // 하위
    
    // MARK: - 초기화
    init(id: UUID = UUID(),
         title: String,
         note: String? = nil,
         isCompleted: Bool = false,
         setTime: Int = 25,          // 분 단위
         elapsedTime: Int = 0,       // 초 단위
         createdAt: Date = .now,
         performedDate: Date? = nil,
         order: Int = 0,
         parent: Todo? = nil) {
        self.id = id
        self.title = title
        self.note = note
        self.isCompleted = isCompleted
        self.setTime = setTime
        self.elapsedTime = elapsedTime
        self.createdAt = createdAt
        self.performedDate = performedDate
        self.order = order
        self.parent = parent
    }
    
    // MARK: - 편의(기존 코드 호환용)
    // 편의
    var childrenArray: [Todo] { children.sorted { $0.order < $1.order } }
}
