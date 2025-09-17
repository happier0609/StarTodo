//
//  SplashView.swift
//  StarTodo
//
//  Created by 조민경 on 9/11/25.
//

import SwiftUI

struct SplashView: View {
    @State private var showAppName = false
    @State private var offsetY: CGFloat = 0
    @State private var navigateToMain = false

    var body: some View {
        ZStack {
            StarFieldView()
            
            VStack(spacing: 30) {
                Image("Kapi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .offset(y: offsetY)
                    .onAppear {
                        startFloatingAnimation()
                    }

                if showAppName {
                    Text("StarTodo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            offsetY = -10
            withAnimation(.easeIn(duration: 1.0).delay(0.3)) {
                showAppName = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                navigateToMain = true
            }
        }
        .fullScreenCover(isPresented: $navigateToMain) {
            RootView()
        }
    }

    private func startFloatingAnimation() {
        withAnimation(.easeInOut(duration: 1.5)) {
            offsetY = 10
        }

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                offsetY = offsetY == 10 ? -10 : 10
            }
        }
    }
}

#Preview {
    SplashView()
}
