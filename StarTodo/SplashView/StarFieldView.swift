//
//  StarFieldView.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import SwiftUI

struct StarFieldView: View {
    @State private var stars: [Star] = []

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in

                    for index in stars.indices {
                        // 별의 위치 업데이트
                        stars[index].y += stars[index].speed

                        // 화면 아래로 떨어지면 위로 다시 이동
                        if stars[index].y > size.height {
                            stars[index].y = 0
                            stars[index].x = CGFloat.random(in: 0..<size.width)
                        }

                        // 별 그리기
                        let rect = CGRect(x: stars[index].x,
                                          y: stars[index].y,
                                          width: stars[index].size,
                                          height: stars[index].size)

                        context.fill(Path(ellipseIn: rect), with: .color(Color("White").opacity(stars[index].opacity)))
                    }
                }
            }
            .background(Color("BgDark"))
            .onAppear {
                stars = (0..<100).map { _ in
                    Star(
                        x: CGFloat.random(in: 0..<geo.size.width),
                        y: CGFloat.random(in: 0..<geo.size.height),
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
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
}


//#Preview {
//    SplashView()
//}
