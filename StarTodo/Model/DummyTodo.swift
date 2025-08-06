//
//  DummyTodo.swift
//  StarTodo
//
//  Created by 조민경 on 8/5/25.
//

import Foundation

struct DummyTodo: Identifiable, Equatable {
    let id: UUID
    let title: String
    let setTime: Int        // 단위: 분
    var elapsed: Int        // 단위: 초
    var isCompleted: Bool

    func markedAsCompleted() -> DummyTodo {
        var copy = self
        copy.isCompleted = true
        return copy
    }
}
