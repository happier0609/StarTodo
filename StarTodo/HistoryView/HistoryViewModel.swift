//
//  HistoryViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import Foundation
import SwiftData

/// HistoryViewModel은 집중 세션(FocusSession) 데이터를 SwiftData에서 불러와 정리하고, 뷰에 제공하는 역할을 수행
///     •    저장된 FocusSession을 불러오기
///     •    최신순으로 정렬
///     •    각 세션의 완료된 할 일 수, 집중 시간 등을 계산
///     •    뷰에서 사용할 수 있도록 가공된 데이터 제공

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [FocusSession] = []
    @Published var cardViewDataList: [HistoryCardViewData] = []
    private let context: ModelContext
    
    // MARK: - 초기화
    
    init(context: ModelContext) {
        self.context = context
        loadSessions()
    }
    
    // MARK: - 세션 불러오기
    
    func loadSessions() {
        // 임시 예시 (나중에 predicate로 날짜별 정렬도 가능)
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        do {
            sessions = try context.fetch(descriptor)
            cardViewDataList = sessions.map { HistoryCardViewData(session: $0) }
        } catch {
            print("⚠️ 세션 불러오기 실패: \(error.localizedDescription)")
            sessions = []
            cardViewDataList = []
        }
    }
}
