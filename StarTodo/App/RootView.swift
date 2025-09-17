//
//  RootView.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftUI
import SwiftData

/// 앱의 루트 뷰: SplashView 이후 진입하여 MainViewModel과 Repository를 주입하는 진입점
struct RootView: View {
    // SwiftData에서 자동으로 주입되는 모델 컨텍스트
    @Environment(\.modelContext) private var mc

    // 상태를 유지하는 Box 객체들 (최초 1회 생성됨)
    @StateObject private var repoBox = RepoBox()
    @StateObject private var mainVMBox = MainVMBox()

    var body: some View {
        ContentView()
            .environmentObject(repoBox)
            .environmentObject(mainVMBox)
            // ✅ View가 나타날 때 초기화 수행 (경고 없이 안전한 타이밍)
            .onAppear {
                Task { @MainActor in
                    repoBox.setIfNeeded(with: mc)
                    mainVMBox.setIfNeeded(with: mc)
                }
            }
    }
}
