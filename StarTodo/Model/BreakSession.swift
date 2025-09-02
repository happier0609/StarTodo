//
//  BreakSession.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
import SwiftData
/// 각 휴식의 시작 시각, 종료 시각, 총 길이(초 단위) 등을 기록

struct BreakSession: Identifiable, Codable {
    let id: UUID
    let start: Date
    let end: Date
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
