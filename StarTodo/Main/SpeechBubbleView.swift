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
        VStack(alignment: .trailing, spacing: 0) {
            if tailPosition == .top {
                BubbleTail()
                    .fill(backgroundColor)
                    .frame(width: 20, height: 10)
                    .offset(x: -10)
            }
            
            Text(text)
                .typo(.textSMEmphasized)
                .foregroundColor(Color("App.White"))
                .multilineTextAlignment(.trailing)
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
                    .offset(x: -10)
            }
        }
    }
}

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // 꼭짓점 중앙을 기준으로 좌우 1/4만 사용 (각이 더 좁아짐)
        let tipX = width / 2
        let baseWidth = width * 0.5  // 밑변을 전체의 50%로 좁게 설정

        path.move(to: CGPoint(x: tipX, y: 1)) // 꼭짓점
        path.addLine(to: CGPoint(x: tipX + baseWidth / 2, y: height))
        path.addLine(to: CGPoint(x: tipX - baseWidth / 2, y: height))
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
            text: "꼬리가 아래에 있는 말풍선\n가나다라마사ㅏ어롸넝롸어롸넝롼어롸ㅓㄴㅇ롸언로",
            tailPosition: .bottom
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
#endif

