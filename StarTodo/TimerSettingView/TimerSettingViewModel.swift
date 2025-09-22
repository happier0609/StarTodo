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
    
    /// FocusSettingView에서 전달된 UUID 목록 (순서 유지)
    var selectedTodoIDs: [UUID]
    
    /// 전체 Todo 목록 (ID 기준으로 필터링함)
    var allTodos: [Todo]
    
    // MARK: - 사용자 입력 상태
    
    /// 각 Todo에 대해 사용자가 설정한 집중 시간 (분 단위)
    /// nil = 시간 설정 없음, Int = 설정된 시간(분)
    var selectedTimes: [UUID: Int?] = [:]
    
    
    // MARK: - 초기화
    
    /// 생성자: 선택된 Todo ID 목록과 전체 Todo 리스트를 받아 초기화
    init(selectedTodoIDs: [UUID], allTodos: [Todo]) {
        self.selectedTodoIDs = selectedTodoIDs
        self.allTodos = allTodos
        
        // 초기값 설정: 선택된 각 Todo ID에 대해 원래 setTime을 기본값으로 설정
        for id in selectedTodoIDs {
            if let todo = allTodos.first(where: { $0.id == id }) {
                // 원래 Todo의 setTime이 0이면 nil(시간 없음), 아니면 그 값 사용
                selectedTimes[id] = todo.setTime > 0 ? todo.setTime : nil
            } else {
                selectedTimes[id] = nil  // 찾을 수 없으면 시간 없음
            }
        }
        
        print("TimerSettingViewModel 초기화")
        print("선택된 Todo IDs: \(selectedTodoIDs)")
        print("초기 시간 설정: \(selectedTimes)")
    }
    
    
    // MARK: - 출력 데이터
    
    /// 선택된 ID 목록을 기반으로 순서를 유지하며 Todo 객체 배열을 구성
    var displayedTodos: [Todo] {
        selectedTodoIDs.compactMap { id in
            allTodos.first(where: { $0.id == id })
        }
    }
    
    /// 현재까지 설정된 모든 집중 시간을 합산한 총 예상 시간 (분 단위)
    /// 시간이 설정되지 않은(nil) 항목은 제외
    var totalMinutes: Int {
        selectedTimes.values.compactMap { $0 }.reduce(0, +)
    }
    
    /// 시간 설정이 있는 Todo 목록 (UUID + 시간) → FocusModeView로 전달
    /// 시간이 없음(nil)인 경우 0으로 전달
    var todosWithTime: [(UUID, Int)] {
        selectedTodoIDs.map { id in
            // selectedTimes[id]는 Int?? 타입
            // 첫 번째 ?는 Dictionary lookup, 두 번째 ?는 저장된 Int? 값
            if let storedValue = selectedTimes[id] {
                return (id, storedValue ?? 0)  // storedValue가 nil이면 0
            } else {
                return (id, 0)  // 키가 없으면 0
            }
        }
    }
    
    /// 시간이 설정된 Todo의 개수
    var todosWithTimeCount: Int {
        selectedTimes.values.compactMap { $0 }.count
    }
    
    /// 시간이 설정되지 않은 Todo의 개수
    var todosWithoutTimeCount: Int {
        selectedTodoIDs.count - todosWithTimeCount
    }
    
    
    // MARK: - 상태 변경 함수
    
    /// 특정 Todo에 대해 시간 설정 값을 변경
    /// - Parameters:
    ///   - id: 설정 대상 Todo의 UUID
    ///   - time: 설정할 시간 (nil이면 '시간 없음')
    func setTime(for id: UUID, to time: Int?) {
        selectedTimes[id] = time
        print("시간 설정 변경: \(id) -> \(time?.description ?? "시간 없음")")
    }
    
    /// 특정 Todo의 시간 설정을 '없음'으로 변경
    func clearTime(for id: UUID) {
        selectedTimes[id] = nil
        print("시간 설정 제거: \(id)")
    }
}
