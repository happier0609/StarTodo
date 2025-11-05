//
//  ReportHeaderView.swift
//  StarTodo
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
            .frame(maxWidth: .infinity, alignment: .center)

            // ⏱ 총 집중 시간
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

// MARK: - Glowing Text Component

struct GlowingText: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy))
            .monospacedDigit()
            .foregroundColor(Color("BgLight"))
            .shadow(color: .white.opacity(0.8), radius: 4)
    }
}

// MARK: - Preview

#if DEBUG
struct ReportHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 기본 프리뷰
            ReportHeaderView(
                totalTasks: 5,
                completedTasks: 3,
                totalHours: 1,
                totalMinutes: 35
            )
            .padding()
            .background(Color("BgDark"))
            .previewDisplayName("기본 - 5개 중 3개 완료")
            
            // 전체 완료 프리뷰
            ReportHeaderView(
                totalTasks: 6,
                completedTasks: 6,
                totalHours: 3,
                totalMinutes: 20
            )
            .padding()
            .background(Color("BgDark"))
            .previewDisplayName("전체 완료 - 6개 중 6개")
            
            // 긴 시간 프리뷰
            ReportHeaderView(
                totalTasks: 10,
                completedTasks: 8,
                totalHours: 5,
                totalMinutes: 47
            )
            .padding()
            .background(Color("BgDark"))
            .previewDisplayName("긴 시간 - 5시간 47분")
            
            // 0개 완료 프리뷰
            ReportHeaderView(
                totalTasks: 4,
                completedTasks: 0,
                totalHours: 0,
                totalMinutes: 25
            )
            .padding()
            .background(Color("BgDark"))
            .previewDisplayName("0개 완료")
        }
    }
}
#endif
