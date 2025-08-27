//
//  RootView.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var mc
    @StateObject private var repoBox = RepoBox()

    var body: some View {
        ContentView()
            .environmentObject(repoBox.makeRepo(with: mc))
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
