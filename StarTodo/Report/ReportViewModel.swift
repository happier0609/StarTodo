//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel (SwiftData 버전)
@MainActor
final class ReportViewModel: ObservableObject {

    // 전체 할 일 목록 (이번 세션에서 "수행됨" 표식이 있는 항목들만 전달받아 사용)
    @Published var todos: [Todo] = []

    // 완료/미완료 분리 리스트 (UI 편의용)
    @Published var completedTodos: [Todo] = []
    @Published var incompletedTodos: [Todo] = []

    // MARK: - 데이터 로딩

    /// 완료 여부와 상관없이, "수행된(performedDate != nil)" 항목만 리포트 대상으로 채택
    /// 동시에 완료/미완료 리스트를 분리 저장
    func fetchTodos(from allTodos: [Todo]) {
        // 수행된 항목만
        let performed = allTodos.filter { $0.performedDate != nil }

        // 정렬(옵션): 완료 여부 → order → 생성일
        self.todos = performed.sorted {
            // 미완료가 먼저 오고, 그 다음 order, createdAt
            if $0.isCompleted != $1.isCompleted {
                return $0.isCompleted == false
            }
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }

        self.completedTodos   = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
    }

    // MARK: - 총합/통계 (⚠️ elapsedTime은 "초" 단위)

    /// 총 집중 시간(초)
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedTime }
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

    /// 전체 할 일 개수(수행된 것만 집계)
    var totalCount: Int { todos.count }

    /// 완료한 할 일 개수
    var completedCount: Int { completedTodos.count }

    // MARK: - 계획 시간(분) 관련

    /// 전체 수행 항목의 계획 시간(setTime, 분) 합 (모든 항목이 0초가 아니어야 합산)
    /// - 모든 항목의 setTime이 0보다 큰 경우에만 합산; 아니면 nil
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setTime }             // 분
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

    /// 개별 할 일의 계획/실제 시간 비교 텍스트
    /// - 완료된 항목만 비교
    /// - 계획 시간이 0분이면 nil
    func timeDescription(for todo: Todo) -> String? {
        guard todo.isCompleted else { return nil }

        let plannedMin = todo.setTime               // 분
        let actualMin  = todo.elapsedTime / 60      // 초 → 분

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
