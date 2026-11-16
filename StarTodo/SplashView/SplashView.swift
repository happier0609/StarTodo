//
//  SplashView.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import SwiftUI

/// 앱 실행 시 잠깐 보여주는 스플래시
/// - 별이 흐르는 우주 배경 위에서 캐릭터(Kapi)가 둥실 떠 있고, 앱 이름이 서서히 나타남
/// - 약 2초 뒤 onFinish를 호출하고, StarTodoApp이 스플래시를 페이드아웃으로 걷어냄
struct SplashView: View {
    var onFinish: () -> Void = {}

    @State private var isFloating = false
    @State private var showAppName = false

    var body: some View {
        ZStack {
            StarFieldView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("Kapi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 140)
                    .offset(y: isFloating ? -10 : 10)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isFloating)

                Text("StarTodo")
                    .font(.spartan(.bold, size: 40))
                    .foregroundColor(Color("App.White"))
                    .opacity(showAppName ? 1 : 0)
            }
        }
        .onAppear {
            isFloating = true
            withAnimation(.easeIn(duration: 1.0).delay(0.3)) {
                showAppName = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onFinish()
            }
        }
    }
}

#Preview {
    SplashView()
}
