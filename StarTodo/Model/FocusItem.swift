//
//  FocusItem.swift
//  StarTodo
//
//  Created by 조민경 on 8/25/25.
//

import Foundation
import SwiftData
// 집중모드에 들어갔을 때 측정되는 단위

@Model
final class FocusItem {
    var title: String
    var setSeconds: Int
    var elapsedSeconds: Int
    var isCompleted: Bool
    var order: Int

    init(title: String, setSeconds: Int, elapsedSeconds: Int, isCompleted: Bool, order: Int) {
        self.title = title
        self.setSeconds = setSeconds
        self.elapsedSeconds = elapsedSeconds
        self.isCompleted = isCompleted
        self.order = order
    }
}
