//
//  TimerSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import SwiftUI

struct TimerSettingView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @State private var viewModel: TimerSettingViewModel
    
    // 생성자에서 ViewModel 주입
    init(selectedIDs: [UUID], allTodos: [Todo]) {
        _viewModel = State(initialValue: TimerSettingViewModel(selectedTodoIDs: selectedIDs, allTodos: allTodos))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("목록을 확인하고")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
            Text("목표 시간을 설정해주세요")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("Cool1100"))
        }
        
        VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 12) {
                    // ✅ 선택된 Todo 목록 표시
                    ForEach(viewModel.displayedTodos, id: \.id) { todo in
                        let parentTitle = todo.parent?.title
                        
                        TimerItemRowView(
                            item: todo,
                            parentTitle: parentTitle,
                            selectedTime: viewModel.selectedTimes[todo.id] ?? nil,
                            onTimeChange: { viewModel.setTime(for: todo.id, to: $0) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // ✅ 총 시간 표시
            let totalMinutes = viewModel.totalMinutes
            let hour = totalMinutes / 60
            let minute = totalMinutes % 60
            let timeString = (hour > 0 ? "\(hour)시간 " : "") + "\(minute)분"
            
            HStack(spacing: 0) {
                Text("\(timeString)")
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("Primary600"))
                Text(" 소요 예정")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool1100"))
            }
            
            // ✅ 시작 버튼
            Button(action: {
                let idPairs: [(UUID, Int)] = viewModel.todosWithTime.enumerated().map { ($0.element.0, $0.offset) }
                let input = FocusTodoInput(todoIDPairs: idPairs)

                coordinator.push(.focusMode(input: input))
            }) {
                Text("이대로 시작하기")
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("White"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("Primary600"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("List")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
    }
}

#Preview {
    let dummyTodos = [
        DummyTodo(id: UUID(), title: "할 일 1", setTime: 25, elapsed: 0, isCompleted: false, setSeconds: 1500, order: 0),
        DummyTodo(id: UUID(), title: "할 일 2", setTime: 15, elapsed: 0, isCompleted: false, setSeconds: 900, order: 1)
    ]
    
    let selectedIDs = dummyTodos.map { $0.id }
    let allTodos = dummyTodos.map { Todo(id: $0.id, title: $0.title, setTime: $0.setTime, order: $0.order) }
    
    return TimerSettingView(
        selectedIDs: selectedIDs,
        allTodos: allTodos
    )
    .environmentObject(MainCoordinator.preview())
}
