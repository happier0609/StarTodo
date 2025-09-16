//
//  MainViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//


/// 역할: 전역 상태, 현재 페이지, 기본 fetch/save

import Foundation
import SwiftData
import SwiftUI

// 메인 페이지 흐름 정의
enum MainPage {
    case addTodo
    case focusSetting
}

@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - 앱 전체 상태 관리
    
    /// 전체 할 일 목록 (SwiftData에서 불러온 후 UI에 표시)
    @Published var todoEntities: [Todo] = []

    /// 현재 앱 화면 상태 (탭 또는 단계)
    @Published var currentPage: MainPage = .addTodo

    /// FocusSettingView에서 선택한 Todo의 UUID 목록
    /// - TimerSettingView 등에서 사용하기 위한 공유 상태 (Coordinator 패턴과 연계 가능)
    @Published var selectedIDs: [UUID] = []

    /// 완료 기준 시간 (ex. 새벽 5시 기준으로 하루 단위 리셋)
    @AppStorage("resetHour") var resetHour: Int = 5


    // MARK: - SwiftData 관련

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchTodos()
    }

    // MARK: - Fetch 로직

    func fetchTodos() {
        do {
            // 1. 전체 할 일 Fetch (정렬 없음)
            let fd = FetchDescriptor<Todo>()
            var list = try context.fetch(fd)

            // 2. 메모리 내 정렬 (미완료 → 완료 → order → createdAt)
            list.sort {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted && $1.isCompleted }
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.createdAt < $1.createdAt
            }

            // 3. 상태 반영
            todoEntities = list
        } catch {
            print("❌ SwiftData fetch 실패:", error.localizedDescription)
            todoEntities = []
        }
    }

    // MARK: - 리셋 기준 시각 계산

    var completionResetTime: Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comp.hour = resetHour
        return Calendar.current.date(from: comp) ?? .now
    }

    // MARK: - Save (삽입/수정/삭제 후 호출)

    func saveContextAndRefresh() {
        do {
            try context.save()
            fetchTodos()
        } catch {
            print("❌ SwiftData save 실패:", error.localizedDescription)
        }
    }
}
