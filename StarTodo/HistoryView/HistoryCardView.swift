//
//  HistoryCardView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryCardView: View {
    let data: HistoryCardViewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. 완료 원 (최대 10개 + 나머지는 +n)
            HStack(spacing: 6) {
                ForEach(0..<min(data.completedCount, 10), id: \.self) { _ in
                    Circle()
                        .fill(Color("Primary200"))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color("Primary200").opacity(0.8), radius: 1)
                }
                if data.completedCount > 10 {
                    Text("+\(data.completedCount - 10)")
                        .font(.caption2)
                        .foregroundColor(Color("Info300"))
                }
            }
            
            // 2. 집중 시간 + 완료 개수
            HStack {
                Text("\(data.focusMinutes)분 집중")
                Spacer()
                Text("\(data.completedCount)개 완료")
            }
            .typo(.captionMDRegular)
            .foregroundColor(Color("Cool1100"))
            
            // 3. 날짜 (덜 강조)
            Text(data.dateText)
                .typo(.captionMDRegular)
                .foregroundColor(Color("Cool300"))
        }
        .padding()
        .background(Color("BgLight"))
        .foregroundColor(.white)
        .cornerRadius(16)
    }
}

// MARK: - 프리뷰용 더미 세션 만들기
private let previewSession: FocusSession = {
    let session = FocusSession(
        startedAt: Date().addingTimeInterval(-75 * 60),
        endedAt: Date(),
        totalBreakSeconds: 0
    )
    
    session.items = [
        FocusItem(title: "할일1", setSeconds: 0, elapsedSeconds: 0, isCompleted: true,  order: 0),
        FocusItem(title: "할일2", setSeconds: 0, elapsedSeconds: 0, isCompleted: true,  order: 1),
        FocusItem(title: "할일3", setSeconds: 0, elapsedSeconds: 0, isCompleted: true,  order: 2),
        FocusItem(title: "할일4", setSeconds: 0, elapsedSeconds: 0, isCompleted: true,  order: 3),
        FocusItem(title: "할일5", setSeconds: 0, elapsedSeconds: 0, isCompleted: false, order: 4),
        FocusItem(title: "할일6", setSeconds: 0, elapsedSeconds: 0, isCompleted: false, order: 5),
    ]
    
    return session
}()

#Preview {
    let data = HistoryCardViewData(session: previewSession)
    HistoryCardView(data: data)
        .padding()
        .background(Color.black)
}
