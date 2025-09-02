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
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ record: FocusSessionRecord) {
        let session = FocusSession(
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            totalBreakSeconds: record.totalBreakSeconds
        )
        
        // ⏱ FocusItem 변환 및 추가
        session.items = record.todos.enumerated().map { index, todo in
            FocusItem(
                title: todo.title,
                setSeconds: todo.setTime * 60,
                elapsedSeconds: todo.elapsed,
                isCompleted: todo.isCompleted,
                order: index
            )
        }

        // 💤 BreakSession 변환 및 추가
        session.breaks = record.breaks.map { breakRecord in
            BreakSession(
                start: breakRecord.start,
                end: breakRecord.end
            )
        }

        // 💾 SwiftData 저장
        context.insert(session)
        do {
            try context.save()
            print("✅ FocusSession 저장 성공")
        } catch {
            print("❌ SwiftData 저장 실패:", error.localizedDescription)
        }
    }
}
