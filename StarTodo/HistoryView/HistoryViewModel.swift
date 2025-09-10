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
    
    /// 년, 월 단위로 그룹화된 세션 카드 뷰 데이터
    @Published var groupedByYear: [YearSection] = []
    @Published var groupedByMonth: [MonthSection] = []
    
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

            // 3. 연/월 단위 키로 그룹핑 (💡 튜플 대신 Hashable struct 사용)
            let monthGroups = Dictionary(grouping: cardDataList) { data -> YearMonthKey in
                let components = Calendar.current.dateComponents([.year, .month], from: data.date)
                let year = String(format: "%04d", components.year ?? 0)
                let month = String(format: "%02d", components.month ?? 0)
                let monthTitle = "\(components.month ?? 0)월"
                return YearMonthKey(year: year, id: "\(year)-\(month)", title: monthTitle)
            }

            // 4. 연도 기준으로 1차 그룹화
            let grouped = Dictionary(grouping: monthGroups) { $0.key.year }

            // 5. 최종 정렬 및 가공된 섹션 구성
            self.groupedByYear = grouped
                .sorted { $0.key > $1.key } // 연도 최신순
                .map { year, monthEntries in
                    let months: [MonthSection] = monthEntries
                        .map { entry in
                            let key = entry.key       // YearMonthKey
                            let dataList = entry.value
                            return MonthSection(
                                id: key.id,          // "2025-09"
                                title: key.title,    // "9월"
                                sessions: dataList
                            )
                        }
                        .sorted { $0.id > $1.id } // 월 최신순 정렬

                    return YearSection(
                        id: year,
                        title: "\(year)년",
                        months: months
                    )
                }

        } catch {
            print("⚠️ 세션 불러오기 실패: \(error.localizedDescription)")
            sessions = []
            groupedByYear = []
        }
    }
}

// MARK: - Section을 위한 모델

/// 📦 연 단위로 나눈 집중 세션 그룹
struct YearSection: Identifiable {
    let id: String         // "2025"
    let title: String      // "2025년"
    let months: [MonthSection]
}

/// 📦 월 단위로 나눈 집중 세션 그룹
struct MonthSection: Identifiable {
    let id: String              // 예: "2025-09" (연-월)
    let title: String           // 예: "2025년 9월"
    let sessions: [HistoryCardViewData]
}

// MARK: - 내부 모델 키 정의

/// 📦 연도+월 정보를 나타내는 키 구조체
private struct YearMonthKey: Hashable {
    let year: String       // 예: "2025"
    let id: String         // 예: "2025-09"
    let title: String      // 예: "9월"
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
            
            // 👉 월 단위로 먼저 그룹핑
            let monthGroups = Dictionary(grouping: cardDataList) { data -> YearMonthKey in
                let components = Calendar.current.dateComponents([.year, .month], from: data.date)
                let year = String(format: "%04d", components.year ?? 0)
                let monthNum = String(format: "%02d", components.month ?? 0)
                let monthTitle = "\(components.month ?? 0)월"
                
                return YearMonthKey(year: year, id: "\(year)-\(monthNum)", title: monthTitle)
            }
            
            // 👉 연도 단위로 다시 그룹핑
            let grouped = Dictionary(grouping: monthGroups) { $0.key.year }

            // 👉 최종적으로 연 → 월 구조의 groupedByYear 구성
            viewModel.groupedByYear = grouped
                .sorted { $0.key > $1.key }
                .map { year, monthEntries in
                    let months: [MonthSection] = monthEntries
                        .map { entry in
                            let key = entry.key
                            let dataList = entry.value
                            return MonthSection(
                                id: key.id,
                                title: key.title,
                                sessions: dataList
                            )
                        }
                        .sorted { $0.id > $1.id }

                    return YearSection(
                        id: year,
                        title: "\(year)년",
                        months: months
                    )
                }
            
            return viewModel
        } catch {
            fatalError("❌ Preview용 ModelContainer 생성 실패: \(error)")
        }
    }
}
