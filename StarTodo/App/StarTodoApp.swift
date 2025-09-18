//
//  JPS_3App.swift
//  JPS_3
//
//  Created by ChoMinKyung on 3/12/25.
//

import SwiftUI
import SwiftData

@main
struct StarTodoApp: App {
    @StateObject private var coordinator = MainCoordinator.shared

    var body: some Scene {
        WindowGroup {
            ModelContextProvider { context in
                RootView()
                    .environment(\.modelContext, context)
                    .environmentObject(coordinator)
                    .environmentObject(MainViewModel(context: context)) // ✅ 여기서 context 주입
            }
        }
        .modelContainer(for: [Todo.self, FocusSession.self, FocusItem.self, BreakSession.self])
    }
}
