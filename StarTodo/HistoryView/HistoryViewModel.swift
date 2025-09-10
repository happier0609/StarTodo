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
///     • 월 단위로 그룹화하여 섹션 형태로 정리
///     • HistoryCardView에 최적화된 데이터(HistoryCardViewData)로 가공
@MainActor
final class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties

    /// 원본 FocusSession 목록
    @Published var sessions: [FocusSession] = []

    /// 뷰에 표시할 카드용 데이터 목록 (미사용 가능성 있음)
    @Published var cardViewDataList: [HistoryCardViewData] = []

    /// 월 단위로 그룹화된 세션 카드 뷰 데이터
    @Published var groupedSessions: [MonthSection] = []

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

    /// 저장된 집중 세션을 최신순으로 불러오고,
    /// HistoryCardViewData로 가공한 후 월별 섹션으로 그룹화
    func loadSessions() {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            // 1. 세션 불러오기
            sessions = try context.fetch(descriptor)
            
            // 2. 카드 뷰 데이터로 변환
            let cardDataList = sessions.map { HistoryCardViewData(session: $0) }
            self.cardViewDataList = cardDataList
            
            // 3. 월 단위로 그룹핑
            self.groupedSessions = Dictionary(grouping: cardDataList) { data in
                let components = Calendar.current.dateComponents([.year, .month], from: data.date)
                return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)  // "2025-09"
            }
            .sorted(by: { $0.key > $1.key }) // 최신 월부터 정렬
            .map { key, dataList in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "yyyy년 M월"
                let firstDate = dataList.first?.date ?? Date()
                return MonthSection(
                    id: key,
                    title: formatter.string(from: firstDate),
                    sessions: dataList
                )
            }
        } catch {
            print("⚠️ 세션 불러오기 실패: \(error.localizedDescription)")
            sessions = []
            cardViewDataList = []
            groupedSessions = []
        }
    }
}

// MARK: - Section을 위한 모델

/// 📦 월 단위로 나눈 집중 세션 그룹
struct MonthSection: Identifiable {
    let id: String              // 예: "2025-09" (연-월)
    let title: String           // 예: "2025년 9월"
    let sessions: [HistoryCardViewData]
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

            let cardDataList = sessions.map { HistoryCardViewData(session: $0) }
            viewModel.cardViewDataList = cardDataList

            // 섹션 생성도 포함
            viewModel.groupedSessions = Dictionary(grouping: cardDataList) { data in
                let components = Calendar.current.dateComponents([.year, .month], from: data.date)
                return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            }
            .sorted(by: { $0.key > $1.key })
            .map { key, dataList in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "yyyy년 M월"
                let firstDate = dataList.first?.date ?? Date()
                return MonthSection(
                    id: key,
                    title: formatter.string(from: firstDate),
                    sessions: dataList
                )
            }

            return viewModel
        } catch {
            fatalError("❌ Preview용 ModelContainer 생성 실패: \(error)")
        }
    }
}
