//
//  HistoryCardViewData.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import Foundation
import SwiftData

/// 📘 HistoryCardViewData
/// FocusSession 모델을 UI에서 사용할 수 있도록 가공한 뷰 전용 데이터 구조입니다.
/// - 카드에 표시할 날짜, 집중 시간, 완료된 할 일 수 등을 계산하여 저장합니다.
/// - 월 단위 그룹핑을 위해 `date` 프로퍼티도 포함됩니다.
struct HistoryCardViewData: Identifiable {
    
    // MARK: - Identifiable
    let id: PersistentIdentifier   // SwiftData 모델 고유 식별자
    
    // MARK: - 표시 데이터
    let focusMinutes: Int          // 집중 시간(분)
    let completedCount: Int        // 완료된 할일 수
    let dateText: String           // "9월 11일 (수)"
    let date: Date                 // 그룹핑용 날짜 (startedAt)
    
    // MARK: - 초기화
    init(session: FocusSession) {
        self.id = session.persistentModelID
        
        // 1. 집중 시간 (초 → 분)
        let seconds = Int(session.endedAt.timeIntervalSince(session.startedAt))
        self.focusMinutes = max(0, seconds / 60)
        
        // 2. 완료된 할일 개수
        self.completedCount = session.items.filter { $0.isCompleted }.count
        
        // 3. 날짜 문자열 (예: "9월 11일 (수)")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        self.dateText = formatter.string(from: session.startedAt)
        
        // 4. 그룹핑용 날짜 저장
        self.date = session.startedAt
    }
}
