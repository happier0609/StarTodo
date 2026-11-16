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
    
    // ✅ private(set)으로 외부 접근은 허용하되 수정은 내부에서만
    private(set) var modelContext: ModelContext
    private(set) var repository: TodoRepository
    
    /// FocusSettingView에서 선택한 Todo의 UUID 목록
    /// - TimerSettingView 등에서 사용하기 위한 공유 상태 (Coordinator 패턴과 연계 가능)
    @Published var selectedIDs: [UUID] = []
    
    /// 완료 기준 시간 (ex. 새벽 5시 기준으로 하루 단위 리셋)
    @AppStorage("resetHour") var resetHour: Int = 5
    
    /// FocusSettingViewModel 초기화
    @Published var focusSettingViewModel = FocusSettingViewModel()
    
    func resetFocusSetting() {
        focusSettingViewModel = FocusSettingViewModel()
    }
    
    // MARK: - SwiftData 관련
    
    init(context: ModelContext) {
        // ✅ 1. 먼저 모든 stored property 초기화
        self.modelContext = context
        self.repository = TodoRepository(context: context)
        
        // ✅ 2. 초기화 완료 후에는 fetchTodos를 호출하지 않음
        // (updateContext에서 호출됨)
    }
    
    /// ContentView의 실제 ModelContext로 업데이트
    func updateContext(_ context: ModelContext) {
        self.modelContext = context
        self.repository = TodoRepository(context: context)
        
        // 초기 데이터 로드
        fetchTodos()
        
        print("✅ MainViewModel: Context 업데이트 완료")
    }
    
    // MARK: - ✅ 단일 Fetch 로직
    
    func fetchTodos() {
        do {
            // 1. 전체 할 일 Fetch (정렬 없음)
            let fd = FetchDescriptor<Todo>()
            var list = try modelContext.fetch(fd)
            
            // 2. 메모리 내 정렬 (미완료 → 완료 → order → createdAt)
            list.sort {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted && $1.isCompleted }
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.createdAt < $1.createdAt
            }
            
            // 3. 상태 반영
            todoEntities = list
            
            print("✅ MainViewModel.fetchTodos: \(list.count)개 로드됨")
        } catch {
            print("❌ SwiftData fetch 실패:", error.localizedDescription)
            todoEntities = []
        }
    }
    
    // MARK: - ✅ 명시적 새로고침
    
    /// Report 복귀 및 앱 재진입 시 명시적으로 호출하여 Todo 목록 갱신
    func refreshTodos() {
        print("🔄 MainViewModel.refreshTodos 호출")
        fetchTodos()
        // ❌ 노티피케이션 제거 - @Published가 자동으로 UI 갱신
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
            try modelContext.save()
            fetchTodos()
        } catch {
            print("❌ SwiftData save 실패:", error.localizedDescription)
        }
    }
    
    // MARK: - ✅ Computed Properties (하위 뷰모델용)
    
    /// AddListView용: 부모 할 일만 필터링
    var parentTodos: [Todo] {
        todoEntities.filter { $0.parent == nil }
    }
    
    /// FocusSettingView용: 미완료 부모 할 일만 필터링
    var uncompletedParentTodos: [Todo] {
        todoEntities.filter { parent in
            guard parent.parent == nil && !parent.isCompleted else { return false }
            
            // 자식이 없으면 표시
            if parent.children.isEmpty { return true }
            
            // 미완료 자식이 하나라도 있으면 표시
            return parent.children.contains { !$0.isCompleted }
        }
    }
}
