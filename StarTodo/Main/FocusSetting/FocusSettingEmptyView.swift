//
//  FocusSettingEmptyView.swift
//  StarTodo
//
//  Created by 조민경 on 9/1/25.
//

import SwiftUI

struct FocusSettingEmptyView: View {
    @State private var showBubble = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image("Empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                
                Text("완벽보다 중요한 건 시작하는 용기.\n지금 해낼 수 있는 일들을 선택해요")
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Info1200"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showBubble = true
                            }
                            
                            // 3초 후 자동으로 숨기기
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showBubble = false
                                }
                            }
                        }) {
                            Image("Help")
                        }
                        .buttonStyle(.plain)
                        
                        if showBubble {
                            SpeechBubbleView(
                                text: "집중모드는 내가 해야 할 일을\n‘진짜’ 실행할 수 있게 돕는 기능이에요.",
                                tailPosition: .top
                            )
                            .transition(.opacity)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(18)
    }
}

#if DEBUG
#Preview {
    FocusSettingEmptyView()
}
#endif
