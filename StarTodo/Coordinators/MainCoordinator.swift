//
//  AppCoordinator.swift
//  StarTodo
//
//  Created by 조민경 on 9/14/25.
//

import SwiftUI
import SwiftData

// MARK: - FocusModeView에 넘길 데이터 구조
/// FocusModeView로 넘어가는 데이터의 구조화된 모델
/// - todoIDPairs: 할일의 UUID와 순서 정보
struct FocusTodoInput: Hashable {
    let todoIDPairs: [(UUID, Int)]
    
    static func == (lhs: FocusTodoInput, rhs: FocusTodoInput) -> Bool {
        lhs.todoIDPairs.elementsEqual(rhs.todoIDPairs, by: { $0.0 == $1.0 && $0.1 == $1.1 })
    }
    
    func hash(into hasher: inout Hasher) {
        for pair in todoIDPairs {
            hasher.combine(pair.0)
            hasher.combine(pair.1)
        }
    }
}

// MARK: - 화면 전환을 위한 Enum
/// 화면 전환 시 구체적인 데이터를 함께 넘기는 enum
enum MainScreen: Hashable {
    case focusSetting
    case timerSetting(selectedIDs: [UUID], allTodos: [Todo])
    case focusMode(input: FocusTodoInput)
    case report(sessionID: PersistentIdentifier)
}

// MARK: - Coordinator
/// MainView 전용 Coordinator (FocusSettingView ~ ReportView 관리)
final class MainCoordinator: ObservableObject {
    
    // ✅ 싱글톤 인스턴스 (앱 전역에서 하나만 사용됨)
    static let shared = MainCoordinator()
    
    // ✅ 외부에서 생성 막기 (싱글톤 패턴)
    private init() {}
    
    // ✅ NavigationStack 경로 관리
    @Published var path = NavigationPath()
    
    // ✅ 다음 화면으로 push
    func push(_ screen: MainScreen) {
        path.append(screen)
    }
    
    // ✅ 이전 화면으로 pop
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    // ✅ 처음 화면으로 pop
    func popToRoot() {
        path.removeLast(path.count)
    }
}

// MARK: - Preview 전용 이니셜라이저
#if DEBUG
extension MainCoordinator {
    static func preview() -> MainCoordinator {
        return MainCoordinator()
    }
}
#endif
