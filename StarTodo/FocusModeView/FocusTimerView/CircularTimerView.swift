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
            // CHANGED: 내부 원 (첫 번째 60분)
            innerCircle
            
            // NEW: 외부 원 (두 번째 60분, 60분 초과 시에만 표시)
            if elapsedTime > 3600 {
                outerCircle
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
    
    // MARK: - 내부 원 (첫 60분)
    private var innerCircle: some View {
        ZStack {
            // 🔵 회색 배경: 설정 시간만큼만 표시 (최대 60분)
            Circle()
                .trim(from: 0, to: innerBackgroundTrimRatio)
                .stroke(Color("Cool600"), lineWidth: 6)
                .frame(width: innerCircleSize, height: innerCircleSize)
                .rotationEffect(.degrees(-90))

            // ⚪️ 흰색 진행: 첫 60분 진행률
            Circle()
                .trim(from: 0, to: innerProgressRatio)
                .stroke(Color("App.White"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: innerCircleSize, height: innerCircleSize)
                .rotationEffect(.degrees(-90))

            // ✨ 끝 점 (내부 원)
            if elapsedTime <= 3600 {
                innerEndDot
            }
        }
    }
    
    // MARK: - 외부 원 (60-120분)
    private var outerCircle: some View {
        ZStack {
            // ⚪️ 흰색 진행: 60-120분 진행률
            Circle()
                .trim(from: 0, to: outerProgressRatio)
                .stroke(Color("App.White"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: outerCircleSize, height: outerCircleSize)
                .rotationEffect(.degrees(-90))
            
            // ✨ 끝 점 (외부 원)
            outerEndDot
        }
    }
    
    // MARK: - 내부 원 끝 점
    private var innerEndDot: some View {
        GeometryReader { geometry in
            let radius = innerCircleSize / 2
            let angle = Angle(degrees: 360 * Double(innerProgressRatio) - 90)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            let x = center.x + radius * cos(CGFloat(angle.radians))
            let y = center.y + radius * sin(CGFloat(angle.radians))

            Circle()
                .fill(Color("App.White"))
                .frame(width: 14, height: 14)
                .position(x: x, y: y)
                .shadow(color: Color("App.White").opacity(0.8), radius: 6)
        }
    }
    
    // MARK: - 외부 원 끝 점
    private var outerEndDot: some View {
        GeometryReader { geometry in
            let radius = outerCircleSize / 2
            let angle = Angle(degrees: 360 * Double(outerProgressRatio) - 90)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            let x = center.x + radius * cos(CGFloat(angle.radians))
            let y = center.y + radius * sin(CGFloat(angle.radians))

            Circle()
                .fill(Color("App.White"))
                .frame(width: 14, height: 14)
                .position(x: x, y: y)
                .shadow(color: Color("App.White").opacity(0.8), radius: 6)
        }
    }

    // MARK: - 크기 설정
    private var innerCircleSize: CGFloat {
        250 // 내부 원 크기
    }
    
    private var outerCircleSize: CGFloat {
        320 // 외부 원 크기
    }

    // MARK: - 내부 원 계산
    
    // 🟡 회색 배경 원 (설정 시간만큼, 최대 60분)
    private var innerBackgroundTrimRatio: CGFloat {
        let effectiveSetTime = min(setTime, 60) // 최대 60분
        if effectiveSetTime == 0 { return 0 } // 시간 설정이 없으면 회색 배경 없음
        return CGFloat(effectiveSetTime) / 60.0
    }

    // ⚪️ 흰색 진행 바 (첫 60분 진행률)
    private var innerProgressRatio: CGFloat {
        let clampedElapsed = min(elapsedTime, 3600) // 최대 3600초(60분)
        return CGFloat(clampedElapsed) / 3600.0
    }
    
    // MARK: - 외부 원 계산
    
    // ⚪️ 흰색 진행 바 (60-120분 진행률)
    private var outerProgressRatio: CGFloat {
        if elapsedTime <= 3600 { return 0 }
        let secondRoundElapsed = min(elapsedTime - 3600, 3600) // 3600초 초과분, 최대 3600초
        return CGFloat(secondRoundElapsed) / 3600.0
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
                // CHANGED: 120분(7200초)까지 진행
                if elapsedTime < 120 * 60 {
                    elapsedTime += 1
                }
            }
    }
}

#Preview("45분 설정 - 시작") {
    CircularTimerPreviewWrapper(setTime: 45)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgDark"))
}

#Preview("30분 설정 - 50분 경과") {
    struct Preview: View {
        @State private var elapsedTime = 50 * 60 // 50분
        
        var body: some View {
            CircularTimerView(setTime: 30, elapsedTime: elapsedTime)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BgDark"))
        }
    }
    return Preview()
}

#Preview("45분 설정 - 70분 경과") {
    struct Preview: View {
        @State private var elapsedTime = 70 * 60 // 70분 (외부 원 10분 진행)
        
        var body: some View {
            CircularTimerView(setTime: 45, elapsedTime: elapsedTime)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BgDark"))
        }
    }
    return Preview()
}

#Preview("시간 없음 - 30분 경과") {
    struct Preview: View {
        @State private var elapsedTime = 30 * 60 // 30분
        
        var body: some View {
            CircularTimerView(setTime: 0, elapsedTime: elapsedTime)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BgDark"))
        }
    }
    return Preview()
}
