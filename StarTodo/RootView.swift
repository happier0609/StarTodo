//
//  RootView.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftUI
import SwiftData

final class RepoBox: ObservableObject {
    @Published private(set) var repo: TodoRepository?

    @MainActor
    func makeRepo(with mc: ModelContext) -> TodoRepository {
        if let r = repo { return r }                   // 이미 있으면 재사용
        let r = TodoRepository(context: mc)            // 처음 한 번만 생성
        repo = r
        return r
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var mc        // ← 환경에서 가져온 ModelContext
    @StateObject private var repoBox = RepoBox()       // 생명주기 고정

    var body: some View {
        ContentView()
            .environmentObject(repoBox.makeRepo(with: mc))
            // ↑ 여기서 트리 전체에 레포를 주입(1회 생성/지속)
    }
}
