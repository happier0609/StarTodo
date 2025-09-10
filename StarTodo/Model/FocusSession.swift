//
//  FocusSession.swift
//  StarTodo
//
//  Created by 조민경 on 8/25/25.
//

import Foundation
import SwiftData

// ✅ 그냥 기본 init만 사용해도 충분!
@Model
final class FocusSession {
    var startedAt: Date
    var endedAt: Date
    var totalBreakSeconds: Int

    @Relationship(deleteRule: .cascade) var items: [FocusItem] = []
    @Relationship(deleteRule: .cascade, inverse: \BreakSession.session)
    var breaks: [BreakSession] = []

    init(startedAt: Date, endedAt: Date, totalBreakSeconds: Int = 0) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.totalBreakSeconds = totalBreakSeconds
    }
}
