//
//  AppCoordinator.swift
//  StarTodo
//
//  Created by 조민경 on 9/14/25.
//

import SwiftUI

enum AppScreen: Hashable {
    case main
    case focusSetting
    case timerSetting(todoIDs: [UUID])
    case focusMode(todoIDs: [UUID])
    case report(sessionID: UUID)
}

class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func push(_ screen: AppScreen) {
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
