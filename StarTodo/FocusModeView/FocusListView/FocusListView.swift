//
//  FocusListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

struct FocusListView: View {
    @ObservedObject var viewModel: FocusModeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.todos.enumerated()), id: \.offset) { index, todo in
                        FocusListRowView(
                            title: todo.title,
                            isCompleted: todo.isCompleted,
                            isCurrent: index == viewModel.currentIndex,
                            onComplete: {
                                viewModel.markCurrentTodoAsCompleted()
                            }
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("Cool000"))
                )
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

//MARK: - 기존 코드

//import SwiftUI
//
//struct FocusListView: View {
//    @ObservedObject var viewModel: FocusModeViewModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            
//            ScrollView {
//                VStack(spacing: 8) {
//                    ForEach(Array(viewModel.todoStates.enumerated()), id: \.offset) { index, state in
//                        FocusListRowView(
//                            title: state.todo.wrappedTitle,
//                            isCompleted: state.isCompleted,
//                            isCurrent: index == viewModel.currentIndex,
//                            onComplete: {
//                                viewModel.markCurrentTodoAsCompleted()
//                            }
//                        )
//                    }
//                }
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Color("Cool000"))
//                )
//                .padding(.horizontal)
//            }
//            
//            Spacer()
//        }
//    }
//}
