//
//  ReportListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportListView: View {
    let todos: [TodoEntity]
    let getComment: (TodoEntity) -> String?
    let isCompleted: (TodoEntity) -> Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(todos, id: \.wrappedID) { todo in
                    HStack(alignment: .top) {
                        ZStack {
                            if isCompleted(todo) {
                                Circle()
                                    .fill(Color("White"))
                                    .frame(width: 24, height: 24)
                                    .shadow(color: Color("White").opacity(0.8), radius: 6) // Glow 효과
                            } else {
                                Circle()
                                    .stroke(Color("Cool100"), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.top, 2)
                        
                        // ✅ 텍스트 및 설명
                        Text(todo.wrappedTitle)
                            .typo(.textMDRegular)
                            .foregroundColor(Color("BgLight"))
                        
                        if let comment = getComment(todo), todo.isCompleted {
                            Text(comment)
                                .typo(.textSMEmphasized)
                                .foregroundColor(Color("Info200"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }
}
