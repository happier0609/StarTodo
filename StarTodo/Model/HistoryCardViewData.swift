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
        // 결과판(ReportViewModel)과 같은 기준: 할 일별 실제 집중 시간의 합
        // (종료-시작 시각 차이로 계산하면 휴식 시간까지 포함되어 결과판과 달라짐)
        let seconds = session.items.reduce(0) { $0 + $1.elapsedSeconds }
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
