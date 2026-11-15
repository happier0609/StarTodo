//
//  StarFieldView.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import SwiftUI

/// 별이 위에서 아래로 천천히 흐르는 우주 배경
/// - 별 위치를 상태로 매 프레임 바꾸지 않고, 시작 위치 + 흐른 시간으로 계산
///   (그리기 도중 @State를 바꾸면 "Modifying state during view update" 경고가 나고 애니메이션이 끊김)
struct StarFieldView: View {
    @State private var stars: [Star] = []
    @State private var startDate = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                Canvas { context, size in
                    guard size.height > 0 else { return }
                    for star in stars {
                        // 초당 speed × 60pt 속도로 내려오고, 화면 아래로 나가면 위에서 다시 등장
                        let travelled = star.y * size.height + star.speed * 60 * elapsed
                        let y = travelled.truncatingRemainder(dividingBy: size.height)
                        let rect = CGRect(x: star.x * size.width, y: y, width: star.size, height: star.size)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(Color("App.White").opacity(star.opacity)))
                    }
                }
            }
            .background(Color("BgDark"))
            .onAppear {
                startDate = Date()
                // 위치는 화면 크기에 대한 비율(0~1)로 저장해 회전·크기 변화에도 그대로 사용
                stars = (0..<100).map { _ in
                    Star(
                        x: CGFloat.random(in: 0..<1),
                        y: CGFloat.random(in: 0..<1),
                        size: CGFloat.random(in: 2...6),
                        speed: CGFloat.random(in: 0.5...1.5),
                        opacity: Double.random(in: 0.6...1.0)
                    )
                }
            }
        }
    }
}

struct Star {
    var x: CGFloat        // 가로 위치 비율 (0~1)
    var y: CGFloat        // 시작 세로 위치 비율 (0~1)
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
}

#Preview {
    StarFieldView()
}
