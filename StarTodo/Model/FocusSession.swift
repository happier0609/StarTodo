//
//  FocusSession.swift
//  StarTodo
//
//  Created by 조민경 on 8/25/25.
//

import Foundation
import SwiftData
// 한 번의 집중 모드 실행(시작 시간, 종료 시간, 휴식 합계 등)

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
