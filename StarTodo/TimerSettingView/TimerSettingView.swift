//
//  TimerSettingView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import SwiftUI
import SwiftData

struct TimerSettingView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TimerSettingViewModel
    
    // 생성자에서 ViewModel 주입
    init(selectedIDs: [UUID], allTodos: [Todo]) {
        _viewModel = State(initialValue: TimerSettingViewModel(selectedTodoIDs: selectedIDs, allTodos: allTodos))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            customHeader
            
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
                                onTimeChange: { newTime in
                                    viewModel.setTime(for: todo.id, to: newTime)
                                }
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
                
                // ✅ 시작 버튼 (수정된 로직)
                Button(action: {
                    // todosWithTime에서 (UUID, Int) 튜플 배열을 가져옴
                    let todoTimePairs = viewModel.todosWithTime
                    let input = FocusTodoInput(todoIDPairs: todoTimePairs)
                    MainCoordinator.shared.presentFullScreen(.focusMode(input: input))

                    print("🚀 집중모드 시작 버튼 클릭")
                    print("📋 전달할 데이터: \(todoTimePairs)")
                }) {
                    Text("이대로 시작하기")
                        .typo(.textMDEmphasized)
                        .foregroundColor(Color("App.White"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.todosWithTime.isEmpty ? Color.gray : Color("Primary600"))
                        .cornerRadius(12)
                }
                .disabled(viewModel.todosWithTime.isEmpty)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationBarHidden(true) // 기본 네비게이션 바 숨기기
        .onAppear {
            print("📱 TimerSettingView 나타남")
            print("📋 표시할 Todo 개수: \(viewModel.displayedTodos.count)")
            print("⏰ 현재 시간 설정: \(viewModel.selectedTimes)")
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        ZStack {
            // 중앙 아이콘
            Image("List")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("Primary600"))
            
            // 왼쪽 뒤로가기 버튼
            HStack {
                Button(action: {
                    coordinator.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color("Cool200"))
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal)
        .padding(.top, 10)
        .background(Color("App.White"))
    }
}

// MARK: - Preview
#if DEBUG
struct TimerSettingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 기본 Preview
            NavigationView {
                TimerSettingView(
                    selectedIDs: PreviewData.makeSampleTodos().map { $0.id },
                    allTodos: PreviewData.makeSampleTodos()
                )
            }
            .previewDisplayName("기본")
            .previewSetup()
            
            // 부모-자식 구조
            NavigationView {
                let todos = PreviewData.makeTodosWithHierarchy()
                let childrenIDs = todos.filter { $0.parent != nil }.map { $0.id }
                return TimerSettingView(
                    selectedIDs: childrenIDs,
                    allTodos: todos
                )
            }
            .previewDisplayName("부모-자식 구조")
            .previewSetup()
            
            // 단일 항목
            NavigationView {
                let todos = PreviewData.makeSampleTodos()
                return TimerSettingView(
                    selectedIDs: [todos[0].id],
                    allTodos: todos
                )
            }
            .previewDisplayName("단일 항목")
            .previewSetup()
            
            // 다크 모드
            NavigationView {
                TimerSettingView(
                    selectedIDs: PreviewData.makeSampleTodos().map { $0.id },
                    allTodos: PreviewData.makeSampleTodos()
                )
            }
            .previewDisplayName("다크 모드")
            .preferredColorScheme(.dark)
            .previewSetup()
        }
    }
}
#endif
