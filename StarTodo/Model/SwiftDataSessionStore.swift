//
//  SwiftDataSessionStroe.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation
import SwiftData

final class SwiftDataSessionStore: SessionStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func save(_ record: FocusSessionRecord) {
        let session = FocusSession(
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            totalBreakSeconds: record.totalBreakSeconds
        )

        // 할 일 저장
        session.items = record.todos.enumerated().map { idx, t in
            FocusItem(title: t.title,
                      setSeconds: t.setTime * 60,
                      elapsedSeconds: t.elapsed,
                      isCompleted: t.isCompleted,
                      order: idx)
        }

        // 휴식 이력 저장
        session.breaks = record.breaks.map {
            BreakSession(start: $0.start, end: $0.end, session: session)
        }

        context.insert(session)

        do {
            try context.save()
        } catch {
            print("❌ SwiftData save error:", error.localizedDescription)
        }
    }
}
