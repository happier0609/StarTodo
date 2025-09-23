//
//  FocusLockViewModifier.swift
//  StarTodo
//
//  Created by 조민경 on 9/23/25.
//

// 집중모드 잠금 상태 유지 로직 (FocusModeView - ReportView)
import SwiftUI

struct FocusLockViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                hideTabBar(true)
                disableSwipeBack()
            }
            .onDisappear {
                hideTabBar(false)
                enableSwipeBack()
            }
            .navigationBarBackButtonHidden(true)
    }

    // 탭바 숨기기
    private func hideTabBar(_ hidden: Bool) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let tabBarController = window.rootViewController as? UITabBarController else { return }

        tabBarController.tabBar.isHidden = hidden
    }

    // 스와이프 뒤로가기 차단
    private func disableSwipeBack() {
        findNavController()?.interactivePopGestureRecognizer?.isEnabled = false
    }

    // 다시 허용
    private func enableSwipeBack() {
        findNavController()?.interactivePopGestureRecognizer?.isEnabled = true
    }

    // 현재 뷰의 UINavigationController 찾기
    private func findNavController() -> UINavigationController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else {
            return nil
        }
        return findNavController(from: root)
    }

    private func findNavController(from vc: UIViewController) -> UINavigationController? {
        if let nav = vc as? UINavigationController {
            return nav
        }
        for child in vc.children {
            if let found = findNavController(from: child) {
                return found
            }
        }
        return nil
    }
}

extension View {
    func focusLocked() -> some View {
        self.modifier(FocusLockViewModifier())
    }
}
