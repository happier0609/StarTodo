//
//  AppCoordinator.swift
//  StarTodo
//
//  Created by 조민경 on 9/14/25.
//

import SwiftUI

enum MainScreen: Hashable {
    case focusSetting
    case timerSetting(selectedIDs: [UUID], allTodos: [Todo])
    case focusMode(todoIDs: [UUID])
    case report(sessionID: UUID)
}

class MainCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ screen: MainScreen) {
        path.append(screen)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
