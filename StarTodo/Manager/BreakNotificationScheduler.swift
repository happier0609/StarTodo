//
//  BreakNotificationScheduler.swift
//  StarTodo
//
//  휴식 종료 시각에 로컬 알림을 보내는 도우미
//  - 앱이 백그라운드에 있거나 화면이 꺼져 있어도 휴식이 끝났음을 알려줌
//  - 앱이 화면에 떠 있을 때는 기존 BreakEndOverlay가 안내를 담당
//

import Foundation
import UserNotifications

enum BreakNotificationScheduler {

    private static let identifier = "startodo.breakEnd"

    /// 지금부터 `seconds` 뒤에 휴식 종료 알림을 예약
    /// 처음 호출될 때 알림 권한을 요청하고, 허용된 경우에만 예약함
    static func schedule(after seconds: TimeInterval) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        // 권한 팝업에 응답하는 동안 흐른 시간만큼 밀리지 않도록 종료 시각을 먼저 고정
        let fireDate = Date().addingTimeInterval(seconds)

        // 이전에 예약된 휴식 알림이 있으면 교체
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("❌ 알림 권한 요청 실패: \(error.localizedDescription)")
                return
            }
            guard granted else {
                print("알림 권한이 없어 휴식 종료 알림을 예약하지 않습니다.")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "휴식 시간 종료!"
            content.body = "탐사를 다시 시작해볼까요?"
            content.sound = .default

            let remaining = fireDate.timeIntervalSinceNow
            guard remaining > 1 else { return }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error {
                    print("❌ 휴식 종료 알림 예약 실패: \(error.localizedDescription)")
                } else {
                    print("⏰ 휴식 종료 알림 예약: \(Int(remaining))초 뒤")
                }
            }
        }
    }

    /// 예약된 휴식 종료 알림을 취소 (휴식을 일찍 끝내거나 세션을 종료할 때)
    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
