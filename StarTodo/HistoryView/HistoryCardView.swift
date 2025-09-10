//
//  HistoryCardView.swift
//  StarTodo
//
//  Created by 조민경 on 9/9/25.
//

import SwiftUI

struct HistoryCardView: View {
    let focusMinutes: Int
    let completedCount: Int
    let dateText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. 완료 원 (최대 10개 + 나머지는 +n)
            HStack(spacing: 6) {
                ForEach(0..<min(completedCount, 10), id: \.self) { _ in
                    Circle()
                        .fill(Color("Primary200"))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color("Primary200").opacity(0.8), radius: 1)
                }
                if completedCount > 10 {
                    Text("+\(completedCount - 10)")
                        .font(.caption2)
                        .foregroundColor(Color("Info300"))
                }
            }
            
            // 2. 집중 시간 + 완료 개수
            HStack {
                Text("\(focusMinutes)분 집중")
                Spacer()
                Text("\(completedCount)개 완료")
            }
            .typo(.captionMDRegular)
            .foregroundColor(Color("Cool1100"))
            
            // 3. 날짜 (덜 강조)
            Text(dateText)
                .typo(.captionMDRegular)
                .foregroundColor(Color("Cool300"))
        }
        .padding()
        .background(Color("BgLight"))
        .foregroundColor(.white)
        .cornerRadius(16)
    }
}

#Preview {
    HistoryCardView(focusMinutes: 75, completedCount: 13, dateText: "9월 8일 (월)")
        .padding()}
