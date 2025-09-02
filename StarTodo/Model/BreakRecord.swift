//
//  BreakRecord.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
/// SwiftData와 무관한 임시 메모리용 구조체

struct BreakRecord: Codable {
    var start: Date
    var end: Date
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
