//
//  StarTodoApp.swift
//  StarTodo
//
//  Created by ChoMinKyung on 3/12/25.
//

import SwiftUI
import SwiftData

@main
struct StarTodoApp: App {
    @StateObject private var coordinator = MainCoordinator.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 메인 화면은 스플래시 뒤에서 미리 준비 (데이터 로드가 끝난 상태로 등장)
                ContentView()
                    .environmentObject(coordinator)

                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .modelContainer(for: [
            Todo.self,
            FocusSession.self,
            FocusItem.self,
            BreakSession.self
        ])
    }
}
