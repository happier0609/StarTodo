//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel (SwiftData 버전)
@MainActor
final class ReportViewModel: ObservableObject {
    
    // 전체 할 일 목록 (이번 세션에서 "수행됨" 표식이 있는 항목들만 전달받아 사용)
    @Published var todos: [ReportItem] = []
    
    // 완료/미완료 분리 리스트 (UI 편의용)
    @Published var completedTodos: [ReportItem] = []
    @Published var incompletedTodos: [ReportItem] = []
    
    // MARK: - 초기화
    // session 기반으로 ReportItem 초기화
    init(session: FocusSession) {
        let items = session.items.map {
            ReportItem(
                title: $0.title,
                setSeconds: $0.setSeconds,
                elapsedSeconds: $0.elapsedSeconds,
                isCompleted: $0.isCompleted,
                order: $0.order
            )
        }
        
        // 정렬: 완료 여부 → order 기준
        self.todos = items.sorted {
            if $0.isCompleted != $1.isCompleted {
                return $0.isCompleted == false // 미완료 먼저
            }
            return $0.order < $1.order
        }
        
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
    }
    
    // MARK: - 데이터 로딩
    
    /// 완료 여부와 상관없이, "수행된(performedDate != nil)" 항목만 리포트 대상으로 채택
    /// 동시에 완료/미완료 리스트를 분리 저장
    func fetchTodos(from allTodos: [Todo]) {
        // 1. 수행된 항목만
        let performed = allTodos.filter { $0.performedDate != nil }

        // 2. ReportItem 변환 시 performedDate도 함께 보관
        let reportItems: [ReportItem] = performed.map { todo in
            ReportItem(
                title: todo.title,
                setSeconds: todo.setTime,
                elapsedSeconds: todo.elapsedTime,
                isCompleted: todo.isCompleted,
                order: todo.order,
                performedDate: todo.performedDate
            )
        }

        // 3. 정렬: 완료된 항목은 performedDate 기준 정렬, 미완료는 뒤로
        self.todos = reportItems.sorted {
            switch ($0.performedDate, $1.performedDate) {
            case let (.some(date1), .some(date2)):
                return date1 < date2
            case (.some, .none):
                return true  // performedDate가 있는 게 먼저
            case (.none, .some):
                return false // performedDate가 없는 게 나중
            case (.none, .none):
                return false
            }
        }

        // 4. 완료/미완료 분리
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
    }
    
    // MARK: - 총합/통계

    /// 총 집중 시간(초)
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedSeconds }
    }

    /// 총 집중 시간(분)
    var totalFocusedMinutes: Int {
        totalFocusedSeconds / 60
    }

    /// 총 집중 시간 텍스트: "X시간 Y분"
    var totalFocusedTimeText: String {
        let hours = totalFocusedMinutes / 60
        let minutes = totalFocusedMinutes % 60
        return "\(hours)시간 \(minutes)분"
    }

    /// 전체 할 일 개수
    var totalCount: Int { todos.count }

    /// 완료한 할 일 개수
    var completedCount: Int { completedTodos.count }

    // MARK: - 계획 시간 관련

    /// 전체 수행 항목의 계획 시간(setTime, 분) 합 (모든 항목이 0초가 아니어야 합산; 아니면 nil)
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setSeconds / 60 }  // 초 → 분
        guard mins.allSatisfy({ $0 > 0 }) else { return nil }
        return mins.reduce(0, +)
    }

    /// 총 실제 시간 vs 총 계획 시간 비교 텍스트 (예: "5분 일찍 완료", "10분 더 집중")
    var timeComparisonMessage: String? {
        guard let planned = totalPlannedMinutes else { return nil }

        let actual = totalFocusedMinutes
        if actual > planned {
            return "\(actual - planned)분 더 집중"
        } else if actual < planned {
            return "\(planned - actual)분 일찍 완료"
        } else {
            return nil
        }
    }

    // MARK: - 개별 항목 비교

    /// 개별 ReportItem의 계획/실제 시간 비교 텍스트
    func timeDescription(for item: ReportItem) -> String? {
        guard item.isCompleted else { return nil }

        let plannedMin = item.setSeconds / 60
        let actualMin  = item.elapsedSeconds / 60

        guard plannedMin > 0 else { return nil }

        if actualMin > plannedMin {
            return "\(actualMin - plannedMin)분 더 집중"
        } else if actualMin < plannedMin {
            return "\(plannedMin - actualMin)분 일찍 완료"
        } else {
            return nil
        }
    }
}

extension ReportViewModel {
    
    /// `PersistentIdentifier` 기반으로 SwiftData에서 FocusSession을 불러와 ViewModel을 초기화
    convenience init(sessionID: PersistentIdentifier) {
        
        // 1. SwiftData 컨텍스트 사용 (앱 전체에서 공유되는 기본 컨텍스트)
        let context = defaultContext

        // 2. 주어진 ID와 일치하는 FocusSession을 찾기 위한 FetchDescriptor 정의
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.persistentModelID == sessionID },
            sortBy: [] // 정렬 필요 없음 (ID는 유일함)
        )

        // 3. 해당 FocusSession을 fetch (결과는 배열 → 첫 번째 요소 사용)
        guard let session = try? context.fetch(descriptor).first else {
            // 에러 처리: ID에 해당하는 FocusSession을 찾지 못한 경우 앱 크래시
            fatalError("⚠️ 해당 ID의 FocusSession을 찾을 수 없습니다.")
        }

        // 4. 기존 생성자 호출 (session 기반)
        self.init(session: session)
    }
}
