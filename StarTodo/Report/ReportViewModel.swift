//
//  ReportViewModel.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - 타임라인 아이템 프로토콜
protocol TimelineItem {
    var timestamp: Date { get }
    var displayTitle: String { get }
    var displayTime: String { get }
    var itemType: TimelineItemType { get }
}

enum TimelineItemType {
    case todo
    case breakTime
}

// MARK: - 타임라인용 래퍼 구조체
struct TimelineReportItem: Identifiable, TimelineItem {
    let id = UUID()
    let originalItem: ReportItem
    
    var timestamp: Date {
        originalItem.performedDate ?? Date()
    }
    
    var displayTitle: String {
        originalItem.title
    }
    
    var displayTime: String {
        let minutes = originalItem.elapsedSeconds / 60
        if originalItem.setSeconds > 0 {
            let plannedMin = originalItem.setSeconds / 60
            if minutes > plannedMin {
                return "\(minutes - plannedMin)분 더 집중"
            } else if minutes < plannedMin {
                return "\(plannedMin - minutes)분 일찍 완료"
            }
        }
        return "\(minutes)분 집중"
    }
    
    var itemType: TimelineItemType { .todo }
}

struct TimelineBreakItem: Identifiable, TimelineItem {
    let id = UUID()
    let breakSession: BreakSession
    
    var timestamp: Date {
        breakSession.end // 휴식 종료 시점을 기준으로
    }
    
    var displayTitle: String {
        "휴식"
    }
    
    var displayTime: String {
        let duration = Int(breakSession.duration)
        let minutes = duration / 60
        let seconds = duration % 60
        
        if breakSession.isOverdue {
            return "\(minutes)분 \(seconds)초 (초과)"
        } else {
            return "\(minutes)분 \(seconds)초"
        }
    }
    
    var itemType: TimelineItemType { .breakTime }
}

/// 집중 모드 종료 후 리포트 화면에서 사용하는 ViewModel (SwiftData 버전)
@MainActor
final class ReportViewModel: ObservableObject {
    
    private var session: FocusSession
    
    // 전체 할 일 목록
    @Published var todos: [ReportItem] = []
    
    // 휴식 기록
    @Published var breaks: [BreakSession] = []
    
    // 타임라인 (할 일 + 휴식 통합)
    @Published var timelineItems: [any TimelineItem] = []
    
    // 완료/미완료 분리 리스트 (UI 편의용)
    @Published var completedTodos: [ReportItem] = []
    @Published var incompletedTodos: [ReportItem] = []
    
    // MARK: - 초기화
    init(session: FocusSession) {
        print("리포트 초기화 - 휴식 기록 개수: \(session.breaks.count)")
        
        self.session = session
        self.breaks = session.breaks
        
        // FocusItem -> ReportItem 변환
        let items = session.items.map {
            ReportItem(
                title: $0.title,
                setSeconds: $0.setSeconds,
                elapsedSeconds: $0.elapsedSeconds,
                isCompleted: $0.isCompleted,
                order: $0.order,
                performedDate: session.startedAt.addingTimeInterval(TimeInterval($0.elapsedSeconds))
            )
        }
        
        self.todos = items
        self.completedTodos = todos.filter { $0.isCompleted }
        self.incompletedTodos = todos.filter { !$0.isCompleted }
        
        // 타임라인 생성
        buildTimeline()
    }
    
    // MARK: - 타임라인 빌드
    private func buildTimeline() {
        var timeline: [any TimelineItem] = []
        
        // 완료된 할 일들을 타임라인 아이템으로 변환
        let completedTimelineItems = completedTodos.map { TimelineReportItem(originalItem: $0) }
        timeline.append(contentsOf: completedTimelineItems)
        
        // 휴식 기록을 타임라인 아이템으로 변환
        let breakTimelineItems = breaks.map { TimelineBreakItem(breakSession: $0) }
        timeline.append(contentsOf: breakTimelineItems)
        
        // 시간순 정렬
        timeline.sort { $0.timestamp < $1.timestamp }
        
        self.timelineItems = timeline
    }
    
    // MARK: - 총합/통계
    
    /// 총 집중 시간(초)
    var totalFocusedSeconds: Int {
        todos.reduce(0) { $0 + $1.elapsedSeconds }
    }
    
    /// 총 집중 시간(분)
    var totalFocusedMinutes: Int {
        totalFocusedSeconds / 60
    }
    
    /// 총 휴식 시간(분)
    var totalBreakMinutes: Int {
        session.totalBreakSeconds / 60
    }
    
    /// 총 집중 시간 텍스트: "X시간 Y분"
    var totalFocusedTimeText: String {
        let hours = totalFocusedMinutes / 60
        let minutes = totalFocusedMinutes % 60
        return "\(hours)시간 \(minutes)분"
    }
    
    /// 전체 할 일 개수
    var totalCount: Int { todos.count }
    
    /// 완료한 할 일 개수
    var completedCount: Int { completedTodos.count }
    
    /// 휴식 횟수
    var breakCount: Int { breaks.count }
    
    // MARK: - 계획 시간 관련
    
    /// 전체 수행 항목의 계획 시간(setTime, 분) 합
    var totalPlannedMinutes: Int? {
        let mins = todos.map { $0.setSeconds / 60 }
        guard mins.allSatisfy({ $0 > 0 }) else { return nil }
        return mins.reduce(0, +)
    }
    
    /// 총 실제 시간 vs 총 계획 시간 비교 텍스트
    var timeComparisonMessage: String? {
        guard let planned = totalPlannedMinutes else { return nil }
        
        let actual = totalFocusedMinutes
        if actual > planned {
            return "\(actual - planned)분 더 집중"
        } else if actual < planned {
            return "\(planned - actual)분 일찍 완료"
        } else {
            return nil
        }
    }
    
    // MARK: - 개별 항목 비교
    
    /// 개별 ReportItem의 계획/실제 시간 비교 텍스트
    func timeDescription(for item: ReportItem) -> String? {
        guard item.isCompleted else { return nil }
        
        let plannedMin = item.setSeconds / 60
        let actualMin = item.elapsedSeconds / 60
        
        guard plannedMin > 0 else { return nil }
        
        if actualMin > plannedMin {
            return "\(actualMin - plannedMin)분 더 집중"
        } else if actualMin < plannedMin {
            return "\(plannedMin - actualMin)분 일찍 완료"
        } else {
            return nil
        }
    }
    
    /// 개별 BreakSession의 예정/실제 시간 비교 텍스트
    func breakDescription(for breakSession: BreakSession) -> String {
        let breakMinutes = Int(breakSession.end.timeIntervalSince(breakSession.start) / 60)

        if breakSession.isOverdue {
            return "\(breakMinutes)분 더 충전"
        } else {
            return "\(breakMinutes)분 휴식"
        }
    }
    
    // MARK: - 세션 종료 처리
    func finalizeSession() {
        session.endedAt = Date()
        // SwiftData는 변경사항 자동 저장됨
    }
}

extension ReportViewModel {
    
    /// `PersistentIdentifier` 기반으로 SwiftData에서 FocusSession을 불러와 ViewModel을 초기화
    convenience init(sessionID: PersistentIdentifier) {
        
        let context = defaultContext
        
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.persistentModelID == sessionID },
            sortBy: []
        )
        
        guard let session = try? context.fetch(descriptor).first else {
            fatalError("⚠️ 해당 ID의 FocusSession을 찾을 수 없습니다.")
        }
        
        print("🟢 ReportViewModel 초기화 - sessionID: \(session.persistentModelID)")
        print("🟢 휴식 기록 개수: \(session.breaks.count)")
        
        self.init(session: session)
    }
}
