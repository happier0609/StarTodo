//
//  ReportHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

import SwiftUI

struct ReportHeaderView: View {
    let totalTasks: Int
    let completedTasks: Int
    let totalHours: Int
    let totalMinutes: Int

    var body: some View {
        VStack(spacing: 16) {
            // 🐻 아이콘과 타이틀
            HStack(spacing: 2) {
                Image("Result")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                Text("탐사 결과")
                    .typo(.titleMDemphasized)
                    .foregroundColor(Color("BgLight"))
            }

            // ✨ 달성 요약 멘트
            VStack(spacing: 2) {
                Text("대단해요! 목표한 \(totalTasks)개의 일 중 \(completedTasks)개나 완료했어요.")
                    .multilineTextAlignment(.center)
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Cool300"))

                Text("혹시 달성했는데 체크하는 것을 잊진 않았는지 점검해보세요!")
                    .multilineTextAlignment(.center)
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Cool300"))
            }
            .frame(maxWidth: .infinity, alignment: .center) // ✅ 컨테이너도 중앙 정렬

            // ⏱ 총 집중 시간 타이틀
            VStack(spacing: 4) {
                Text("총 집중 시간")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("BgLight"))

                HStack(spacing: 4) {
                    GlowingText(text: "\(totalHours)", fontSize: 40)
                    Text("시간")
                        .typo(.titleMDemphasized)
                        .foregroundColor(Color("BgLight"))

                    GlowingText(text: "\(totalMinutes)", fontSize: 40)
                    Text("분")
                        .typo(.titleMDemphasized)
                        .foregroundColor(Color("BgLight"))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// GlowingText.swift
struct GlowingText: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy)) // ✅ 실제로 사용
            .monospacedDigit()                             // ✅ 숫자 자간 고정
            .foregroundColor(Color("BgLight"))
            .shadow(color: .white.opacity(0.8), radius: 4)
    }
}

#if DEBUG
struct ReportHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReportHeaderView(
                totalTasks: 5,
                completedTasks: 3,
                totalHours: 1,
                totalMinutes: 35
            )
            .padding()
            .background(Color("BgDark"))
        }
        .previewDisplayName("Report Header")
    }
}
#endif
