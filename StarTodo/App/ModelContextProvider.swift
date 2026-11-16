//
//  ModelContextProvider.swift
//  StarTodo
//
//  Created by 조민경 on 9/15/25.
//

import SwiftUI
import SwiftData

/// SwiftData 기본 컨텍스트 제공자
/// - Preview와 ViewModel 초기화 시점에 사용하는 fallback context
/// - 실제 앱 실행 시에는 @Environment(\.modelContext)를 사용
let defaultContext: ModelContext = {
    do {
        let container = try ModelContainer(
            for: Todo.self,
            FocusSession.self,
            FocusItem.self,
            BreakSession.self
        )
        return ModelContext(container)
        
    } catch {
        fatalError("💥 ModelContainer 생성 실패: \(error)")
    }
}()
