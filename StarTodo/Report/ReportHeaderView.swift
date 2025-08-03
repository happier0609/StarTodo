//
//  ReportHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/3/25.
//

// FocusReportHeaderView.swift
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
                Image("Result") // 🔄 에셋 이름에 맞게 수정 필요
                    .resizable()
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

            // ⏱ 총 집중 시간 타이틀
            VStack(spacing: 4) {
                Text("총 집중 시간")
                    .typo(.textMDRegular)

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
    }
}

// GlowingText.swift
struct GlowingText: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(text)
            .typo(.titleLGEmphasized)
            .foregroundColor(Color("BgLight"))
            .shadow(color: .white.opacity(0.8), radius: 4)
    }
}
