//
//  BreakSession.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
import SwiftData
/// 각 휴식의 시작 시각, 종료 시각, 총 길이(초 단위) 등을 기록

@Model
final class BreakSession {
    var start: Date
    var end: Date
    
    @Relationship var session: FocusSession?
    
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
