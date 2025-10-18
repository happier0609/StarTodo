//
//  FS-SpeechBubbleView.swift
//  StarTodo
//
//  Created by 조민경 on 10/18/25.
//

import SwiftUI

enum TailPosition {
    case top
    case bottom
}

struct SpeechBubbleView: View {
    var text: String
    var tailPosition: TailPosition = .bottom
    var backgroundColor: Color = Color("Info300")

    var body: some View {
        VStack(spacing: 0) {
            if tailPosition == .top {
                BubbleTail()
                    .fill(backgroundColor)
                    .frame(width: 20, height: 10)
                    .offset(x: 50)                          // 👉 오른쪽 이동
            }

            Text(text)
                .typo(.textSMEmphasized)
                .foregroundColor(Color("App.White"))
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)
                )

            if tailPosition == .bottom {
                BubbleTail()
                    .fill(backgroundColor)
                    .frame(width: 20, height: 10)
                    .rotationEffect(.degrees(180))         // 위쪽일 경우 뒤집기
                    .offset(x: 50)                          // 👉 오른쪽 이동
            }
        }
    }
}

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0)) // 꼭짓점
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 40) {
        SpeechBubbleView(
            text: "꼬리가 위에 있는 말풍선",
            tailPosition: .top
        )
        
        SpeechBubbleView(
            text: "꼬리가 아래에 있는 말풍선",
            tailPosition: .bottom
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
#endif

