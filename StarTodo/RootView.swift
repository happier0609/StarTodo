//
//  RootView.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftUI
import SwiftData

// ⭐️ MainViewModel을 한번만 생성해서 여러 뷰에서 공유하기 위한 박스 (Box 객체)
// - ViewModel은 일반적으로 여러 뷰에서 사용되기 때문에 이 박스를 통해 상태를 공유함
final class MainVMBox: ObservableObject {
    @Published private(set) var vm: MainViewModel?

    @MainActor
    func makeVM(with mc: ModelContext) -> MainViewModel {
        // 이미 생성된 ViewModel이 있으면 그대로 사용
        if let vm { return vm }

        // 없으면 새로 생성하고, 저장 후 반환
        let newVM = MainViewModel(context: mc)
        vm = newVM
        return newVM
    }
}

// ⭐️ TodoRepository도 동일하게 공유하기 위한 박스
final class RepoBox: ObservableObject {
    @Published private(set) var repo: TodoRepository?

    @MainActor
    func makeRepo(with mc: ModelContext) -> TodoRepository {
        // 이미 생성된 Repository가 있으면 그대로 사용
        if let r = repo { return r }

        // 없으면 새로 생성하고 저장
        let r = TodoRepository(context: mc)
        repo = r
        return r
    }
}

// ⭐️ 앱의 실제 본격적인 루트 화면
// - 이 RootView는 SplashView 이후 진입하게 되며,
//   MainViewModel과 TodoRepository를 환경변수로 주입함
struct RootView: View {
    // SwiftData에서 자동으로 주입되는 모델 컨텍스트
    @Environment(\.modelContext) private var mc

    // 상태를 유지하는 박스 객체들 (최초 1회 생성됨)
    @StateObject private var repoBox   = RepoBox()
    @StateObject private var mainVMBox = MainVMBox()

    var body: some View {
        // 실제 앱 UI를 구성하는 ContentView에 환경객체 주입
        ContentView()
            .environmentObject(repoBox.makeRepo(with: mc))     // TodoRepository 주입
            .environmentObject(mainVMBox.makeVM(with: mc))     // MainViewModel 주입
    }
}
