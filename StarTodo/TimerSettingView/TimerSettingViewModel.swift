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
    
    /// 생성자: 선택된 Todo ID 목록과 전체 Todo 리스트를 받아 초기화함
    /// - selectedTodoIDs: 집중모드에 포함될 Todo의 UUID 리스트 (순서 유지)
    /// - allTodos: 전체 Todo 리스트
    init(selectedTodoIDs: [UUID], allTodos: [Todo]) {
        self.selectedTodoIDs = selectedTodoIDs
        self.allTodos = allTodos
        
        // 초기값 설정: 선택된 각 Todo ID에 대해 시간은 기본적으로 nil
        for id in selectedTodoIDs {
            selectedTimes[id] = nil
        }
    }
    
    
    // MARK: - 출력 데이터
    
    /// 선택된 ID 목록을 기반으로 순서를 유지하며 Todo 객체 배열을 구성
    var displayedTodos: [Todo] {
        selectedTodoIDs.compactMap { id in
            allTodos.first(where: { $0.id == id })
        }
    }
    
    /// 현재까지 설정된 모든 집중 시간을 합산한 총 예상 시간 (분 단위)
    var totalMinutes: Int {
        selectedTimes.values.compactMap { $0 }.reduce(0, +)
    }
    
    /// 시간 설정이 완료된 Todo 목록 (UUID + 시간) → FocusModeView로 전달 가능
    var todosWithTime: [(UUID, Int)] {
        selectedTimes.compactMap { (id, time) in
            guard let time = time else { return nil }
            return (id, time)
        }
    }
    
    
    // MARK: - 상태 변경 함수
    
    /// 특정 Todo에 대해 시간 설정 값을 변경
    /// - Parameters:
    ///   - id: 설정 대상 Todo의 UUID
    ///   - time: 설정할 시간 (nil이면 '없음')
    func setTime(for id: UUID, to time: Int?) {
        selectedTimes[id] = time
    }
}

#if DEBUG
extension TimerSettingViewModel {
    static func preview(previewTodos: [DummyTodo]) -> TimerSettingViewModel {
        // DummyTodo → Todo 로 매핑하는 로직 필요 (PreviewTodo를 SwiftData Todo로 변환할 수 없다면, 임시 MockTodoModel을 써도 됨)
        let selectedIDs = previewTodos.map { $0.id }
        
        // 더미 Todo로 SwiftData 없이 작동하도록 가짜 Todo 객체를 만든다고 가정
        let allTodos = previewTodos.map {
            Todo(id: $0.id, title: $0.title, setTime: $0.setTime, order: $0.order)
        }

        return TimerSettingViewModel(selectedTodoIDs: selectedIDs, allTodos: allTodos)
    }
}
#endif
