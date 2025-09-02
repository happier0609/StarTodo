//
//  TimerSettingViewModel.swift
//  StarTodo
//
//  Created by 조민경 on 9/2/25.
//

import Foundation
import Observation

@Observable
class TimerSettingViewModel {
    // MARK: - 입력 데이터
    
    /// FocusSettingView에서 전달된 UUID 목록
    /// 집중모드에 포함될 Todo 항목의 ID들 (순서 유지됨)
    var selectedTodoIDs: [UUID]
    
    /// 전체 Todo 목록 (ID 기준으로 필터링함)
    var allTodos: [Todo]
    
    
    // MARK: - 사용자 입력 상태
    
    /// 각 Todo에 대해 사용자가 설정한 집중 시간 (분 단위)
    /// 예: [todoID1: 25, todoID2: nil] → 시간 미설정도 nil로 표현 가능
    var selectedTimes: [UUID: Int?] = [:]
    
    
    // MARK: - 초기화
    
    init(selectedTodoIDs: [UUID], allTodos: [Todo]) {
        self.selectedTodoIDs = selectedTodoIDs
        self.allTodos = allTodos
        
        // 초기화 시, 선택된 ID 목록 기반으로 초기 selectedTimes 구성
        for id in selectedTodoIDs {
            selectedTimes[id] = nil
        }
    }
    
    
    // MARK: - 유틸리티 메서드
    
    /// 선택된 ID 목록에 대응하는 Todo 목록 반환 (순서 유지됨)
    var selectedTodos: [Todo] {
        selectedTodoIDs.compactMap { id in
            allTodos.first(where: { $0.id == id })
        }
    }
    
    /// 최종적으로 FocusModeView에 전달할 (TodoID, 설정 시간) 쌍 반환
    /// nil이 아닌 값만 포함됨
    var todoIDPairsToPass: [(UUID, Int)] {
        selectedTodos.compactMap { todo in
            guard let minutes = selectedTimes[todo.id] ?? nil else { return nil }
            return (todo.id, minutes)
        }
    }
    
    /// 모든 집중 시간의 총합 반환 (분 단위)
    var totalSelectedMinutes: Int {
        selectedTimes.values.compactMap { $0 }.reduce(0, +)
    }
}
