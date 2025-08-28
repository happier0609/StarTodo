//
//  ReportListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import SwiftUI

struct ReportListView: View {
    let todos: [Todo]
    let getComment: (Todo) -> String?
    let isCompleted: (Todo) -> Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(todos, id: \.id) { todo in
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
                        Text(todo.title)
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

#if DEBUG
struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        let t1 = Todo(title: "수학 문제", isCompleted: true,  setTime: 25, elapsedTime: 26*60)
        t1.performedDate = .now
        let t2 = Todo(title: "영단어 암기", isCompleted: false, setTime: 20, elapsedTime: 12*60)
        t2.performedDate = .now

        return ReportListView(
            todos: [t1, t2],
            getComment: { todo in
                // 간단한 데모용 코멘트
                let planned = todo.setTime
                let actual  = todo.elapsedTime / 60
                guard todo.isCompleted, planned > 0 else { return nil }
                if actual > planned { return "\(actual - planned)분 더 집중" }
                if actual < planned { return "\(planned - actual)분 일찍 완료" }
                return nil
            },
            isCompleted: { $0.isCompleted }
        )
        .background(Color("BgDark"))
        .previewDisplayName("Report List")
    }
}
#endif
