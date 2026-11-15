//
//  DemoMode.swift
//  StarTodo
//
//  시연 영상 촬영용 설정 (DEBUG 빌드에서만 동작)
//
//  Xcode ▸ Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments ▸ Arguments Passed On Launch
//    -seedDemoData     : 실행할 때마다 기존 데이터를 지우고 시연용 더미데이터로 채움
//    -demoShortTimer   : 목표 시간·휴식 시간 선택지에 '1분'을 추가 (촬영 시간 단축)
//
//  Release 빌드에서는 두 옵션 모두 항상 꺼져 있어요.
//

import Foundation

enum DemoMode {
    /// 시연용 더미데이터 주입 여부
    static var seedsDemoData: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-seedDemoData")
        #else
        return false
        #endif
    }

    /// 촬영용 짧은 타이머(1분) 선택지 노출 여부
    static var shortTimer: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demoShortTimer")
        #else
        return false
        #endif
    }

    /// 목표 시간 선택지: 기본 5~60분(5분 단위), 시연 모드에서는 1분 추가
    static var focusMinuteOptions: [Int] {
        (shortTimer ? [1] : []) + Array(stride(from: 5, through: 60, by: 5))
    }

    /// 휴식 시간 선택지: 기본 5~30분(5분 단위), 시연 모드에서는 1분 추가
    static var breakMinuteOptions: [Int] {
        (shortTimer ? [1] : []) + Array(stride(from: 5, through: 30, by: 5))
    }
}
