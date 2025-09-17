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
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var coordinator = MainCoordinator.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(viewModel)
                .environmentObject(coordinator)
        }
        .modelContainer(for: [Todo.self, FocusSession.self, FocusItem.self])
    }
}
