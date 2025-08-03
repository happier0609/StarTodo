//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI

class ReportViewModel: ObservableObject {
    // 전체 할 일 목록 (집중모드 수행 완료 후 저장된 항목만)
    @Published var todos: [TodoEntity] = []
    
    // 완료한 할 일들
    @Published var completedTodos: [TodoEntity] = []
    
    // 완료하지 못한 할 일들
    @Published var incompletedTodos: [TodoEntity] = []

    // MARK: - 데이터 불러오기

    /// 완료 여부와 관계없이 수행한 할 일들만 필터링하여 todos에 저장
    /// 동시에 완료/미완료 리스트도 분리 저장
    func fetchTodos(from allTodos: [TodoEntity]) {
        todos = allTodos.filter { $0.performedDate != nil }
        completedTodos = todos.filter { $0.isCompleted }
        incompletedTodos = todos.filter { !$0.isCompleted }
    }

    // MARK: - 통계 정보

    /// 총 집중 시간 (모든 수행된 할 일의 elapsedTime 합산, 단위: 분)
    var totalFocusedTime: Int {
        todos.reduce(0) { $0 + Int($1.elapsedTime) }
    }

    /// 총 집중 시간을 "X시간 Y분" 형식의 텍스트로 반환
    var totalFocusedTimeText: String {
        let hours = totalFocusedTime / 60
        let minutes = totalFocusedTime % 60
        return "\(hours)시간 \(minutes)분"
    }

    /// 전체 할 일 개수
    var totalCount: Int {
        todos.count
    }

    /// 완료한 할 일 개수
    var completedCount: Int {
        completedTodos.count
    }

    // MARK: - 계획 시간 관련

    /// 전체 할 일의 계획 시간(setTime) 합산 (모두 계획이 있을 때만 반환, 없으면 nil)
    var totalPlannedTime: Int? {
        let times = todos.map { Int($0.setTime) }
        guard times.allSatisfy({ $0 > 0 }) else { return nil }
        return times.reduce(0, +)
    }

    /// 총 집중 시간과 계획 시간의 차이를 바탕으로 텍스트 생성
    /// 예: "5분 일찍 완료", "10분 더 집중"
    var timeComparisonMessage: String? {
        guard let planned = totalPlannedTime else { return nil }

        let actual = totalFocusedTime
        if actual > planned {
            return "\(actual - planned)분 더 집중"
        } else if actual < planned {
            return "\(planned - actual)분 일찍 완료"
        } else {
            return nil
        }
    }

    // MARK: - 개별 할 일 시간 비교

    /// 개별 할 일의 계획 시간과 실제 수행 시간 비교
    /// - 완료된 항목만 비교
    /// - 계획 없음(0분)은 nil 반환
    func timeDescription(for todo: TodoEntity) -> String? {
        guard todo.isCompleted else { return nil }

        let planned = Int(todo.setTime)
        let actual = Int(todo.elapsedTime)

        if planned == 0 {
            return nil // 계획 시간 없음
        } else if actual > planned {
            return "\(actual - planned)분 더 집중"
        } else if actual < planned {
            return "\(planned - actual)분 일찍 완료"
        } else {
            return nil // 정확히 일치하거나 기타 조건은 표시 안함
        }
    }
}
