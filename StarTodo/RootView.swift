//
//  RootView.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftUI
import SwiftData

final class MainVMBox: ObservableObject {
    @Published private(set) var vm: MainViewModel?

    @MainActor
    func makeVM(with mc: ModelContext) -> MainViewModel {
        if let vm { return vm }                  // 이미 있으면 재사용
        let newVM = MainViewModel(context: mc)   // 최초 1회 생성
        vm = newVM
        return newVM
    }
}

final class RepoBox: ObservableObject {
    @Published private(set) var repo: TodoRepository?

    @MainActor
    func makeRepo(with mc: ModelContext) -> TodoRepository {
        if let r = repo { return r }
        let r = TodoRepository(context: mc)
        repo = r
        return r
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var mc
    @StateObject private var repoBox   = RepoBox()
    @StateObject private var mainVMBox = MainVMBox()

    var body: some View {
        ContentView()
            .environmentObject(repoBox.makeRepo(with: mc))   // 레포 주입
            .environmentObject(mainVMBox.makeVM(with: mc))   // 메인 뷰모델 주입
    }
}
