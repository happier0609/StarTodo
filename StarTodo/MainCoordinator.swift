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

final class MainCoordinator: ObservableObject {
    // 싱글톤 인스턴스
    static let shared = MainCoordinator()
    
    // 외부에서 생성 막기
    private init() {}

    // 네비게이션 경로
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
