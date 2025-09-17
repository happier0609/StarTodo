//
//  RepoBox.swift
//  StarTodo
//
//  Created by 조민경 on 9/17/25.
//

import SwiftData
import Combine

/// ⭐️ TodoRepository도 동일하게 공유하기 위한 박스
final class RepoBox: ObservableObject {
    @Published private(set) var repo: TodoRepository?

    /// 이미 있으면 그대로 두고, 없으면 새로 생성해서 할당
    @MainActor
    func setIfNeeded(with mc: ModelContext) {
        guard repo == nil else { return }
        repo = TodoRepository(context: mc)
    }
}
