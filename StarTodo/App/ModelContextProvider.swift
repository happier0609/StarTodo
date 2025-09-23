//
//  ModelContextProvider.swift
//  StarTodo
//
//  Created by 조민경 on 9/15/25.
//

import SwiftUI
import SwiftData

/// SwiftData 기본 컨텍스트 제공자
/// - 일반적으로 @Environment(\.modelContext)로 받지만,
///   View의 init 시점에는 사용할 수 없기 때문에 fallback으로 제공함
let defaultContext: ModelContext = {
    do {
        // FocusSession, FocusItem, BreakSession 모델들을 위한 SwiftData 컨테이너 생성
        let container = try ModelContainer(
            for: Todo.self,
            FocusSession.self,
            FocusItem.self,
            BreakSession.self
        )
        // 해당 컨테이너로부터 ModelContext 생성 및 반환
        return ModelContext(container)
        
    } catch {
        // 컨테이너 생성 실패 시 앱을 종료하며 에러 메시지 출력
        fatalError("💥 ModelContainer 생성 실패: \(error)")
    }
}()

/// ModelContext를 하위 뷰에 넘겨주는 Wrapper View
struct ModelContextProvider<Content: View>: View {
    @Environment(\.modelContext) private var context
    let content: (ModelContext) -> Content

    init(@ViewBuilder content: @escaping (ModelContext) -> Content) {
        self.content = content
    }

    var body: some View {
        content(context)
    }
}
