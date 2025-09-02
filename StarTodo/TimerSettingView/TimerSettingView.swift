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
    
    
    // 뷰 body 맨 위쪽에 계산 속성으로 처리
    var selectedTodos: [Todo] {
        let selectedIDs = viewModel.selectedIDs
        return viewModel.todoEntities
            .filter { selectedIDs.contains($0.id) }
            .filter { todo in
                if todo.childrenArray.isEmpty { return true }
                return !todo.childrenArray.contains { child in
                    selectedIDs.contains(child.id)
                }
            }
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
            // 👉 할일 목록 표시 영역
            ScrollView {
                VStack(spacing: 12) {
                    // ✅ 선택된 ID를 기준으로 할일 목록 필터링
                    let selectedIDs = viewModel.selectedIDs
                    let selectedTodos = viewModel.todoEntities
                        .filter { selectedIDs.contains($0.id) }           // wrappedID → id
                        .filter { todo in
                            // 자식이 없으면 그대로 포함
                            if todo.childrenArray.isEmpty { return true }
                            // 자식 중 하나라도 선택되었으면 부모는 제외
                            let childSelected = todo.childrenArray.contains { child in
                                selectedIDs.contains(child.id)             // wrappedID → id
                            }
                            return !childSelected
                        }
                    
                    // ✅ 각 할일 항목 보여주기 (하위 중심, 상위는 작게 표시)
                    ForEach(selectedTodos, id: \.id) { todo in
                        let parentTitle = todo.parent?.title               // wrappedTitle → title
                        
                        TimerItemRowView(
                            item: todo,                                    // ← TimerItemRowView가 Todo를 받도록 수정 필요
                            parentTitle: parentTitle,
                            selectedTime: selectedTimes[todo.id] ?? nil,   // wrappedID → id
                            onTimeChange: { selectedTimes[todo.id] = $0 }  // wrappedID → id
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
                let selectedTodos = viewModel.todoEntities.filter { selectedIDs.contains($0.id) } // id
                
                let todosWithTime: [(UUID, Int)] = selectedTodos.compactMap { todo in
                    guard let time = selectedTimes[todo.id] ?? nil else { return nil }            // id
                    return (todo.id, time)                                                        // id
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
            
//            //             ✅ 버튼 아래에 NavigationLink 추가
//            NavigationLink(
//                destination: FocusModeView(todoIDPairs: todoIDPairsToPass),
//                isActive: $navigateToFocus,
//                label: { EmptyView() }
//            )
//            .hidden() // 화면엔 안 보이게 숨김
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
