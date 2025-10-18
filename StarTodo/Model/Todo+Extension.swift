//
//  Todo+Extensions.swift
//  StarTodo
//
//  Created by 조민경 on 10/19/25.
//

import Foundation
import SwiftData

extension Todo {
    
    // MARK: - 완료 처리
    
    /// 할 일을 완료 처리하고 저장
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - elapsedSeconds: 실제 경과 시간 (초 단위, 옵션)
    @MainActor
    func markAsCompleted(context: ModelContext, elapsedSeconds: Int? = nil) throws {
        print("✅ Todo 완료 처리: \(self.title)")
        
        // 1. 완료 상태 설정
        self.isCompleted = true
        self.performedDate = Date()
        
        // 2. 경과 시간이 제공된 경우 업데이트
        if let elapsed = elapsedSeconds {
            self.elapsedTime = elapsed
            print("  - 경과 시간: \(elapsed)초")
        }
        
        print("  - 완료 시각: \(self.performedDate?.description ?? "nil")")
        
        // 3. 저장
        try context.save()
        print("✅ Todo 완료 상태 저장 성공: \(self.title)")
        
        // 4. 알림 발송 (다른 뷰가 감지할 수 있도록)
        NotificationCenter.default.post(
            name: NSNotification.Name("TodoCompletionChanged"),
            object: nil,
            userInfo: ["todoID": self.id, "isCompleted": true]
        )
    }
    
    /// 할 일 완료를 취소하고 저장
    /// - Parameter context: SwiftData ModelContext
    @MainActor
    func markAsIncomplete(context: ModelContext) throws {
        print("↩️ Todo 완료 취소: \(self.title)")
        
        // 1. 완료 상태 해제
        self.isCompleted = false
        self.performedDate = nil
        
        // 2. 저장
        try context.save()
        print("✅ Todo 완료 취소 저장 성공: \(self.title)")
        
        // 3. 알림 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("TodoCompletionChanged"),
            object: nil,
            userInfo: ["todoID": self.id, "isCompleted": false]
        )
    }
    
    /// 할 일의 완료 상태를 토글
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - elapsedSeconds: 완료 처리 시 설정할 경과 시간 (옵션)
    @MainActor
    func toggleCompletion(context: ModelContext, elapsedSeconds: Int? = nil) throws {
        if isCompleted {
            try markAsIncomplete(context: context)
        } else {
            try markAsCompleted(context: context, elapsedSeconds: elapsedSeconds)
        }
    }
}
