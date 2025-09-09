//
//  HistoryViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import Foundation
import SwiftData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [FocusSession] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        loadSessions()
    }

    func loadSessions() {
        // 임시 예시 (나중에 predicate로 날짜별 정렬도 가능)
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        do {
            sessions = try context.fetch(descriptor)
        } catch {
            print("⚠️ 세션 불러오기 실패: \(error.localizedDescription)")
            sessions = []
        }
    }
}
