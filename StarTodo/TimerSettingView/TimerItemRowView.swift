//
//  TimerItemRowView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/8/25.
//

import SwiftUI

struct TimerItemRowView: View {
    let item: TodoEntity
    let parentTitle: String? // 자식이면 부모 제목 표시용
    let selectedTime: Int?   // nil이면 '없음'
    let onTimeChange: (Int?) -> Void

    private let timeOptions = [nil, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 🧭 부모 제목 표시
            if let parentTitle = parentTitle {
                Text(parentTitle)
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool400"))
            }

            HStack {
                // 🏷 할 일 제목
                Text(item.wrappedTitle)
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool1100"))

                Spacer()

                // ⏱ 시간 선택 메뉴
                Menu {
                    ForEach(timeOptions, id: \.self) { minute in
                        Button(action: {
                            onTimeChange(minute)
                        }) {
                            Text(minuteText(minute))
                        }
                    }
                } label: {
                    Text(minuteText(selectedTime))
                        .typo(.textMDEmphasized)
                        .foregroundColor(Color("Info700"))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color("Primary100"))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color("BgLight"))
        .cornerRadius(10)
    }

    private func minuteText(_ minute: Int?) -> String {
        if let min = minute {
            return "\(min)분"
        } else {
            return "없음"
        }
    }
}
