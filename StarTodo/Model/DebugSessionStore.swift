//
//  DebugSessionStore.swift
//  StarTodo
//
//  Created by 조민경 on 8/26/25.
//

import Foundation

final class DebugSessionStore: SessionStore {
    func save(_ record: FocusSessionRecord) {
        #if DEBUG
        print("✅ Session Saved (stub)",
              "start:", record.startedAt,
              "end:", record.endedAt,
              "break:", record.totalBreakSeconds, "sec",
              "todos:", record.todos.map { "\($0.title)=\($0.elapsed)s/\($0.setTime*60)s" })
        #endif
    }
}
