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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
        }
        .modelContainer(for: [
            Todo.self,
            FocusSession.self,
            FocusItem.self,
            BreakSession.self
        ])
    }
}
