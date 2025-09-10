//
//  HistoryCardViewData.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import Foundation

/// HistoryCardView -> UI 표시용 데이터 변환

struct HistoryCardViewData: Identifiable {
    let id: UUID  // Identifiable을 위한 ID
    let focusMinutes: Int
    let completedCount: Int
    let dateText: String

    init(session: FocusSession) {
        self.id = session.id  // FocusSession에 UUID가 있어야 함 (앞서 추가한 부분)
        
        // 집중 시간 (분)
        let seconds = Int(session.endedAt.timeIntervalSince(session.startedAt))
        self.focusMinutes = seconds / 60
        
        // 완료 항목 수
        self.completedCount = session.items.filter { $0.isCompleted }.count
        
        // 날짜 포맷
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        self.dateText = formatter.string(from: session.startedAt)
    }
}
