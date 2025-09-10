//
//  HistoryCardViewData.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import Foundation
import SwiftData

/// HistoryCardView -> UI 표시용 데이터 변환

struct HistoryCardViewData: Identifiable {
    let id: PersistentIdentifier  // SwiftData 모델의 id 타입
    let focusMinutes: Int
    let completedCount: Int
    let dateText: String

    init(session: FocusSession) {
        self.id = session.persistentModelID   // SwiftData 모델 고유 식별자
        
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
