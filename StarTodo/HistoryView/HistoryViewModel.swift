//
//  HistoryViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import Foundation
import SwiftData

/// 📘 HistoryViewModel
/// 집중 세션(FocusSession) 데이터를 SwiftData에서 불러와 정리하고,
/// 뷰에서 사용할 수 있도록 가공하는 역할을 수행합니다.
///
/// 기능 요약:
///     • 저장된 FocusSession을 최신순으로 불러오기
///     • 각 세션의 완료된 할 일 수, 집중 시간 등을 계산
///     • HistoryCardView에 최적화된 데이터(HistoryCardViewData)로 가공
@MainActor
final class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 원본 FocusSession 목록
    @Published var sessions: [FocusSession] = []
    
    /// 뷰에 표시할 카드용 데이터 목록
    @Published var cardViewDataList: [HistoryCardViewData] = []
    
    // MARK: - Private Properties
    
    /// SwiftData의 ModelContext (의존성 주입 방식)
    private let context: ModelContext
    
    // MARK: - 초기화
    
    /// 기본 생성자
    init(context: ModelContext) {
        self.context = context
        loadSessions()
    }
    
    // MARK: - 세션 불러오기
    
    /// 저장된 집중 세션을 최신순으로 불러오고, 카드용 데이터로 가공
    func loadSessions() {
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

// MARK: - 💡 Preview 지원
extension HistoryViewModel {
    
    /// 프리뷰나 테스트용 ViewModel 생성자
    /// - Parameter sessions: 가짜 FocusSession 데이터 배열
    /// - Returns: 미리 세션을 주입한 ViewModel
    static func preview(_ sessions: [FocusSession]) -> HistoryViewModel {
        do {
            let dummyContext = ModelContext(try ModelContainer(for: FocusSession.self))
            let viewModel = HistoryViewModel(context: dummyContext)
            viewModel.sessions = sessions
            viewModel.cardViewDataList = sessions.map { HistoryCardViewData(session: $0) }
            return viewModel
        } catch {
            fatalError("❌ Preview용 ModelContainer 생성 실패: \(error)")
        }
    }
}
