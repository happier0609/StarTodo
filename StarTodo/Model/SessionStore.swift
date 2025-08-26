//
//  SessionStore.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation

struct FocusSessionRecord {
    var todos: [DummyTodo]
    var startedAt: Date
    var endedAt: Date
    var totalBreakSeconds: Int
}

protocol SessionStore {
    func save(_ record: FocusSessionRecord)
}
