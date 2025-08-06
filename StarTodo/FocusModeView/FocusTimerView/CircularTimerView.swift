//
//  CircularTimerView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 8/2/25.
//

import SwiftUI

struct CircularTimerView: View {
    let setTime: Int       // 분 단위
    let elapsedTime: Int   // 초 단위
    
    @State private var floatUp = false

    var body: some View {
        ZStack {
            // 🔵 회색 원: 설정 시간만큼만 표시 (예: 30분이면 반 원)
            Circle()
                .trim(from: 0, to: backgroundTrimRatio)
                .stroke(Color("Cool600"), lineWidth: 6)
                .frame(width: baseSize, height: baseSize)
                .rotationEffect(.degrees(-90))

            // ⚪️ 흰색 원: 진행률 (항상 전체 원 기준)
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: baseSize, height: baseSize)
                .rotationEffect(.degrees(-90))

            // ✨ 끝 점
            GeometryReader { geometry in
                let radius = baseSize / 2
                let angle = Angle(degrees: 360 * Double(progressRatio) - 90)
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                let x = center.x + radius * cos(CGFloat(angle.radians))
                let y = center.y + radius * sin(CGFloat(angle.radians))

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .position(x: x, y: y)
                    .shadow(color: Color.white.opacity(0.8), radius: 6)
            }

            // 🐻 캐릭터 이미지
            Image("Kapi")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .offset(y: floatUp ? -7 : 7)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: floatUp // 둥실둥실
                )
                .onAppear {
                    floatUp = true
                }
        }
        .padding()
    }

    // ✅ 기준 크기
    private var baseSize: CGFloat {
        250
    }

    // ✅ 총 시간 (초)
    private var totalDurationSeconds: Int {
        setTime * 60
    }

    // ✅ 경과 비율 (0 ~ 1)
    private var progressRatio: CGFloat {
        guard totalDurationSeconds > 0 else { return 0 }
        return min(CGFloat(elapsedTime) / CGFloat(totalDurationSeconds), 1.0)
    }

    // ✅ 회색 배경 원의 trim 비율
    private var backgroundTrimRatio: CGFloat {
        min(CGFloat(setTime) / 60.0, 1.0)
    }
}



//MARK: 프리뷰전용 코드
struct CircularTimerPreviewWrapper: View {
    @State private var elapsedTime: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let setTime: Int

    var body: some View {
        CircularTimerView(setTime: setTime, elapsedTime: elapsedTime)
            .onReceive(timer) { _ in
                if elapsedTime < setTime * 60 {
                    elapsedTime += 1
                }
            }
    }
}

#Preview {
    CircularTimerPreviewWrapper(setTime: 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgDark"))
}
