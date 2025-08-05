//
//  DummyTodo.swift
//  StarTodo
//
//  Created by 조민경 on 8/5/25.
//

import SwiftUI

struct DummyTodo: Identifiable {
    let id: UUID
    let title: String
    var setTime: Int
    var elapsed: Int
    var isCompleted: Bool
}
