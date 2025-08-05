//
//  TimerSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import SwiftUI

struct TimerSettingView: View {
    @EnvironmentObject var viewModel: MainViewModel // MainView에서 넘겨받은 할일/선택 정보
    @State private var selectedTimes: [UUID: Int?] = [:] // 각 할일(UUID)별로 사용자가 설정한 시간
    @State private var navigateToFocus = false // StatusBoardView로 이동할지 여부
    @State private var todoIDPairsToPass: [(UUID, Int)] = []
    
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
            // 👉 할일 목록 표시 영역
            ScrollView {
                VStack(spacing: 12) {
                    // ✅ 선택된 ID를 기준으로 할일 목록 필터링
                    let selectedIDs = viewModel.selectedIDs
                    let selectedTodos = viewModel.todoEntities
                        .filter { selectedIDs.contains($0.wrappedID) }
                        .filter { todo in
                            // 만약 이 할일이 자식이 아닌 경우에만 허용하거나,
                            // 자식이 아니라면 자식 중 하나라도 선택된 경우만 허용
                            if todo.childrenArray.isEmpty {
                                return true // 자식이 없는 할일(진짜 자식)이면 OK
                            } else {
                                // 자식 중 하나라도 선택된 게 있다면, 부모는 제외
                                let selectedChild = todo.childrenArray.contains { child in
                                    selectedIDs.contains(child.wrappedID)
                                }
                                return !selectedChild // 자식이 선택되었으면 부모는 제거
                            }
                        }
                    
                    // ✅ 각 할일 항목 보여주기 (하위 중심, 상위는 작게 표시)
                    ForEach(selectedTodos, id: \.objectID) { todo in
                        let parentTitle = todo.parent?.wrappedTitle
                        
                        TimerItemRowView(
                            item: todo,
                            parentTitle: parentTitle, // 상위 제목이 있을 경우 작게 표시
                            selectedTime: selectedTimes[todo.wrappedID] ?? nil,
                            onTimeChange: { selectedTimes[todo.wrappedID] = $0 }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 👉 총 집중 시간 계산 및 표시
            let totalMinutes = selectedTimes.values.compactMap { $0 }.reduce(0, +)
            let hour = totalMinutes / 60
            let minute = totalMinutes % 60
            let timeString = (hour > 0 ? "\(hour)시간 " : "") + "\(minute)분"
            HStack(spacing: 0){
                Text("\(timeString)")
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("Primary600"))
                Text(" 소요 예정")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool1100"))
            }
            
            // 👉 집중모드 시작 버튼
            Button(action: {
                // 🔄 전역 저장
                viewModel.selectedTodoTimes = selectedTimes.compactMapValues { $0 }
                
                // ✅ 실제 넘길 (할일, 시간) 목록 생성
                let selectedIDs = viewModel.selectedIDs
                let selectedTodos = viewModel.todoEntities.filter {
                    selectedIDs.contains($0.wrappedID)
                }
                
                let todosWithTime: [(UUID, Int)] = selectedTodos.compactMap { todo in
                    guard let time = selectedTimes[todo.wrappedID] ?? nil else { return nil }
                    return (todo.wrappedID, time)
                }
                
                // 전달을 위해 임시 저장
                self.todoIDPairsToPass = todosWithTime
                navigateToFocus = true
                
                let todoIDPairs = todosWithTime

//                FocusModeView(todoIDPairs: todoIDPairs)
                
                // ✅ 화면 전환 트리거
                navigateToFocus = true
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

            // ✅ 버튼 아래에 NavigationLink 추가
            NavigationLink(
                destination: FocusModeView(todoIDPairs: todoIDPairsToPass),
                isActive: $navigateToFocus,
                label: { EmptyView() }
            )
            .hidden() // 화면엔 안 보이게 숨김
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
