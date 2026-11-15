//
//  DemoDataSeeder.swift
//  StarTodo
//
//  시연 영상 촬영용 더미데이터 (DEBUG 빌드 + -seedDemoData 실행 인자에서만 동작)
//  - 오늘 할 일 4개(하위 할 일 포함) + 오늘 완료한 할 일 1개
//  - 이전 할 일 2개
//  - 최근 약 6주간의 집중 기록 14개 (히스토리 화면용, 이번 달·지난달에 걸쳐 표시)
//

#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DemoDataSeeder {

    /// 한 번 실행된 프로세스에서는 다시 주입하지 않음 (onAppear가 여러 번 불려도 안전)
    private static var didSeed = false

    static func seedIfRequested(into context: ModelContext) {
        guard DemoMode.seedsDemoData, !didSeed else { return }
        didSeed = true

        do {
            try removeAll(in: context)
            insertTodos(into: context)
            insertHistory(into: context)
            try context.save()
            print("🌱 DemoDataSeeder: 시연용 더미데이터 주입 완료")
        } catch {
            print("❌ DemoDataSeeder 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 초기화

    private static func removeAll(in context: ModelContext) throws {
        // 세션을 지우면 FocusItem·BreakSession도 cascade로 함께 삭제
        for session in try context.fetch(FetchDescriptor<FocusSession>()) {
            context.delete(session)
        }
        for item in try context.fetch(FetchDescriptor<FocusItem>()) {
            context.delete(item)
        }
        for breakSession in try context.fetch(FetchDescriptor<BreakSession>()) {
            context.delete(breakSession)
        }
        // 상위 할 일을 지우면 하위 할 일도 cascade로 함께 삭제
        for todo in try context.fetch(FetchDescriptor<Todo>()) where todo.parent == nil {
            context.delete(todo)
        }
        try context.save()
    }

    // MARK: - 할 일

    private struct TodoSeed {
        let title: String
        let minutes: Int                 // 목표 시간(분), 0이면 '없음'
        var children: [(String, Int, Bool)] = []   // (제목, 목표 분, 완료 여부)
        var isCompleted = false
        var daysAgo = 0
    }

    private static func insertTodos(into context: ModelContext) {
        let now = Date()
        // 촬영 시간을 줄이려면 -demoShortTimer와 함께 1분 목표를 선택하세요.
        let seeds: [TodoSeed] = [
            TodoSeed(title: "졸업 프로젝트 포스터 마무리", minutes: 25, children: [
                ("앱 화면 캡처 교체", 10, true),
                ("기대효과 문구 다듬기", 15, false),
                ("PDF로 내보내기", 5, false)
            ]),
            TodoSeed(title: "방 정리하기", minutes: 15, children: [
                ("책상 위 치우기", 5, false),
                ("빨래 개기", 10, false),
                ("분리수거 버리기", 5, false)
            ]),
            TodoSeed(title: "교수님께 메일 답장", minutes: 10),
            TodoSeed(title: "병원 예약 전화하기", minutes: 5),
            TodoSeed(title: "아침 스트레칭", minutes: 10, isCompleted: true),
            // 이전 할 일 (어제·그제 만든 미완료 할 일)
            TodoSeed(title: "자료구조 과제 제출", minutes: 40, children: [
                ("문제 3번 풀기", 20, false),
                ("보고서 정리", 20, false)
            ], daysAgo: 1),
            TodoSeed(title: "운동 30분", minutes: 30, daysAgo: 2)
        ]

        for (index, seed) in seeds.enumerated() {
            let created = Calendar.current.date(byAdding: .day, value: -seed.daysAgo, to: now) ?? now
            let parent = Todo(
                title: seed.title,
                isCompleted: seed.isCompleted,
                setTime: seed.minutes,
                elapsedTime: seed.isCompleted ? seed.minutes * 60 : 0,
                createdAt: created,
                performedDate: seed.isCompleted ? now.addingTimeInterval(-20 * 60) : nil,
                order: index
            )

            for (childIndex, child) in seed.children.enumerated() {
                let todo = Todo(
                    title: child.0,
                    isCompleted: child.2,
                    setTime: child.1,
                    elapsedTime: child.2 ? child.1 * 60 : 0,
                    createdAt: created,
                    performedDate: child.2 ? now.addingTimeInterval(-10 * 60) : nil,
                    order: childIndex,
                    parent: parent
                )
                parent.children.append(todo)
            }
            // 앱의 할 일 생성 로직과 같은 순서: 하위를 연결한 뒤 상위를 삽입
            context.insert(parent)
        }
    }

    // MARK: - 히스토리 (집중 기록)

    private struct ItemSeed {
        let title: String
        let setMinutes: Int
        let focusMinutes: Int
        let isCompleted: Bool
    }

    private struct SessionSeed {
        let daysAgo: Int
        let hour: Int
        let items: [ItemSeed]
        let breakMinutes: [Int]          // 휴식 길이(분)
        var overdueBreak = false         // 마지막 휴식이 계획보다 길어졌는지
    }

    private static func insertHistory(into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sessions: [SessionSeed] = [
            SessionSeed(daysAgo: 1, hour: 14, items: [
                ItemSeed(title: "자료구조 과제 문제 1번", setMinutes: 25, focusMinutes: 27, isCompleted: true),
                ItemSeed(title: "자료구조 과제 문제 2번", setMinutes: 25, focusMinutes: 22, isCompleted: true)
            ], breakMinutes: [10]),
            SessionSeed(daysAgo: 2, hour: 20, items: [
                ItemSeed(title: "포스터 레이아웃 잡기", setMinutes: 30, focusMinutes: 34, isCompleted: true),
                ItemSeed(title: "앱 화면 캡처", setMinutes: 15, focusMinutes: 12, isCompleted: true)
            ], breakMinutes: [5]),
            SessionSeed(daysAgo: 4, hour: 10, items: [
                ItemSeed(title: "이메일 정리", setMinutes: 10, focusMinutes: 8, isCompleted: true),
                ItemSeed(title: "장보기 목록 작성", setMinutes: 5, focusMinutes: 5, isCompleted: true),
                ItemSeed(title: "세탁기 돌리기", setMinutes: 5, focusMinutes: 3, isCompleted: true)
            ], breakMinutes: []),
            SessionSeed(daysAgo: 5, hour: 16, items: [
                ItemSeed(title: "결과보고서 초안", setMinutes: 40, focusMinutes: 46, isCompleted: false),
                ItemSeed(title: "참고 자료 찾기", setMinutes: 20, focusMinutes: 18, isCompleted: true)
            ], breakMinutes: [10, 5], overdueBreak: true),
            SessionSeed(daysAgo: 7, hour: 21, items: [
                ItemSeed(title: "운동 30분", setMinutes: 30, focusMinutes: 30, isCompleted: true)
            ], breakMinutes: []),
            SessionSeed(daysAgo: 9, hour: 13, items: [
                ItemSeed(title: "히스토리 버그 수정", setMinutes: 45, focusMinutes: 52, isCompleted: true),
                ItemSeed(title: "커밋 정리", setMinutes: 10, focusMinutes: 9, isCompleted: true)
            ], breakMinutes: [15]),
            SessionSeed(daysAgo: 12, hour: 11, items: [
                ItemSeed(title: "방 청소", setMinutes: 20, focusMinutes: 24, isCompleted: true),
                ItemSeed(title: "분리수거", setMinutes: 5, focusMinutes: 4, isCompleted: true)
            ], breakMinutes: [5]),
            SessionSeed(daysAgo: 15, hour: 19, items: [
                ItemSeed(title: "중간고사 1~3장 복습", setMinutes: 50, focusMinutes: 41, isCompleted: false),
                ItemSeed(title: "요약 노트 만들기", setMinutes: 20, focusMinutes: 20, isCompleted: true)
            ], breakMinutes: [10, 10]),
            SessionSeed(daysAgo: 18, hour: 15, items: [
                ItemSeed(title: "팀 회의 자료 준비", setMinutes: 30, focusMinutes: 28, isCompleted: true)
            ], breakMinutes: [5]),
            SessionSeed(daysAgo: 22, hour: 10, items: [
                ItemSeed(title: "독서 30쪽", setMinutes: 30, focusMinutes: 35, isCompleted: true),
                ItemSeed(title: "독서 기록 남기기", setMinutes: 10, focusMinutes: 7, isCompleted: true)
            ], breakMinutes: [5]),
            SessionSeed(daysAgo: 26, hour: 20, items: [
                ItemSeed(title: "가계부 정리", setMinutes: 15, focusMinutes: 13, isCompleted: true),
                ItemSeed(title: "공과금 납부", setMinutes: 5, focusMinutes: 4, isCompleted: true)
            ], breakMinutes: []),
            SessionSeed(daysAgo: 31, hour: 14, items: [
                ItemSeed(title: "SwiftData 마이그레이션 공부", setMinutes: 60, focusMinutes: 58, isCompleted: true)
            ], breakMinutes: [10], overdueBreak: true),
            SessionSeed(daysAgo: 36, hour: 17, items: [
                ItemSeed(title: "과제 제출", setMinutes: 25, focusMinutes: 31, isCompleted: true),
                ItemSeed(title: "다음 주 일정 정리", setMinutes: 10, focusMinutes: 6, isCompleted: false)
            ], breakMinutes: [5]),
            SessionSeed(daysAgo: 41, hour: 9, items: [
                ItemSeed(title: "아침 루틴", setMinutes: 15, focusMinutes: 15, isCompleted: true),
                ItemSeed(title: "하루 계획 세우기", setMinutes: 10, focusMinutes: 11, isCompleted: true)
            ], breakMinutes: [])
        ]

        for seed in sessions {
            guard let day = calendar.date(byAdding: .day, value: -seed.daysAgo, to: today),
                  let start = calendar.date(bySettingHour: seed.hour, minute: 10, second: 0, of: day)
            else { continue }

            let focusSeconds = seed.items.reduce(0) { $0 + $1.focusMinutes * 60 }

            // 휴식은 집중 시간 중간중간에 균등하게 배치
            var breaks: [BreakSession] = []
            var cursor = start
            let slice = TimeInterval(focusSeconds / (seed.breakMinutes.count + 1))
            for (i, minutes) in seed.breakMinutes.enumerated() {
                let isLast = i == seed.breakMinutes.count - 1
                let overdue = seed.overdueBreak && isLast
                let actualSeconds = TimeInterval(minutes * 60 + (overdue ? 4 * 60 : 0))
                cursor = cursor.addingTimeInterval(slice)
                breaks.append(BreakSession(start: cursor, end: cursor.addingTimeInterval(actualSeconds), isOverdue: overdue))
                cursor = cursor.addingTimeInterval(actualSeconds)
            }
            let breakSeconds = Int(breaks.reduce(0) { $0 + $1.duration })
            let end = start.addingTimeInterval(TimeInterval(focusSeconds + breakSeconds))

            // 앱의 세션 저장 로직(FocusModeViewModel.endFocusSession)과 같은 방식
            let session = FocusSession(startedAt: start, endedAt: end, totalBreakSeconds: breakSeconds)
            context.insert(session)
            session.items = seed.items.enumerated().map { order, item in
                FocusItem(
                    title: item.title,
                    setSeconds: item.setMinutes * 60,
                    elapsedSeconds: item.focusMinutes * 60,
                    isCompleted: item.isCompleted,
                    order: order
                )
            }
            session.breaks = breaks
        }
    }
}
#endif
