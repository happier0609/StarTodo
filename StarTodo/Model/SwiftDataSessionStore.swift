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
        
        // 1️⃣ 할일 저장
        session.items = record.todos.enumerated().map { idx, t in
            FocusItem(title: t.title,
                      setSeconds: t.setTime * 60,
                      elapsedSeconds: t.elapsed,
                      isCompleted: t.isCompleted,
                      order: idx)
        }
        
        // 2️⃣ 휴식 기록 저장
        session.breaks = record.breaks.map { br in
            BreakSession(start: br.start, end: br.end, session: session)
        }
        
        // 3️⃣ 세션 저장
        context.insert(session)
        do {
            try context.save()
            print("✅ FocusSession 저장 성공")
        } catch {
            print("❌ SwiftData 저장 실패:", error.localizedDescription)
        }
    }
}
