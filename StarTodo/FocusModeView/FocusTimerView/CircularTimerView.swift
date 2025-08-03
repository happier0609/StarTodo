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
    
    var body: some View {
        ZStack {
            // MARK: 원 여러개
            //            // 🔵 여러 원 고리
            //            ForEach(0..<numberOfRings, id: \.self) { index in
            //                Circle()
            //                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
            //                    .frame(width: baseSize + CGFloat(index * 24), height: baseSize + CGFloat(index * 24))
            //            }
            //
            //            // ⚪️ 현재 진행률 표시
            //            Circle()
            //                .trim(from: 0, to: progressRatio)
            //                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            //                .frame(width: baseSize + CGFloat((numberOfRings - 1) * 24), height: baseSize + CGFloat((numberOfRings - 1) * 24))
            //                .rotationEffect(.degrees(-90))
            
            // 🔵 회색 배경 원 (1개만!)
            Circle()
                .stroke(Color("Cool600"), lineWidth: 6)
                .frame(width: baseSize, height: baseSize)
            
            // ⚪️ 흰색 진행 바 (elapsedTime 기준)
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: baseSize, height: baseSize)
                .rotationEffect(.degrees(-90))
            
            // ✨ 끝 지점에 원형 점 표시 + Glow
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
                                .shadow(color: Color.white.opacity(0.8), radius: 6, x: 0, y: 0) // Glow 효과
                        }
            
            // 🐻 캐릭터 이미지
            Image("Kapi")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
        }
        .padding()
    }
    
    // MARK: - 계산 프로퍼티
    
    private var baseSize: CGFloat {
        250
    }
    
    // MARK: 원 여러개
    //    private var numberOfRings: Int {
    //        max(1, min(3, (setTime + 59) / 60)) // 60분 기준 1개, 180분 이상은 최대 3개
    //    }
    
    private var totalDurationSeconds: Int {
        setTime * 60
    }
    
    private var progressRatio: CGFloat {
        guard totalDurationSeconds > 0 else { return 0 }
        return min(CGFloat(elapsedTime) / CGFloat(totalDurationSeconds), 1.0)
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("🔵 1시간 중 25분 경과")
        CircularTimerView(setTime: 60, elapsedTime: 25 * 60)
        
        //        Text("🔵 2시간 중 90분 경과")
        //        CircularTimerView(setTime: 120, elapsedTime: 90 * 60)
        //
        //        Text("🔵 3시간 중 170분 경과")
        //        CircularTimerView(setTime: 180, elapsedTime: 170 * 60)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
