//
//  FocusSession.swift
//  StarTodo
//
//  Created by 조민경 on 8/25/25.
//


import SwiftData
// 집중모드에 들어갔을 때 측정되는 단위

@Model
final class FocusSession {
    var startedAt: Date
    var endedAt: Date
    var totalBreakSeconds: Int
    @Relationship(deleteRule: .cascade) var items: [FocusItem] = []

    init(startedAt: Date, endedAt: Date, totalBreakSeconds: Int) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.totalBreakSeconds = totalBreakSeconds
    }
}
