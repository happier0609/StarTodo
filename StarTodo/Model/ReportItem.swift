//
//  ReportItem.swift
//  StarTodo
//
//  Created by 조민경 on 9/8/25.
//

import Foundation

struct ReportItem: Identifiable {
    let id = UUID() // 고유 식별자 (View에서 필요)
    
    let title: String
    let setSeconds: Int
    let elapsedSeconds: Int
    let isCompleted: Bool
    let order: Int

    // 선택적으로 정렬 등에 활용할 수 있음
    var isPerformed: Bool {
        elapsedSeconds > 0 || isCompleted
    }
}

/// Preview용 더미
extension ReportItem {
    static let sample = ReportItem(
        title: "예시 할 일",
        setSeconds: 1800,
        elapsedSeconds: 1500,
        isCompleted: true,
        order: 0
    )
}
