//
//  SessionStore.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation

/// SwiftData 저장 전에 사용하는 집중 세션 임시 기록용 구조체
struct FocusSessionRecord {
    var todos: [DummyTodo]              // 할 일 목록
    var startedAt: Date                 // 집중 시작 시간
    var endedAt: Date                   // 집중 종료 시간
    var totalBreakSeconds: Int          // 총 휴식 시간 (초 단위)
    var breaks: [BreakRecord]           // 개별 휴식 기록
}

/// 개별 휴식 기록을 위한 구조체
struct BreakRecord: Codable {
    var start: Date
    var end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
