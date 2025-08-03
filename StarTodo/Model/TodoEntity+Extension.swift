//
//  TodoEntity+Extension.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/11/25.
//

import Foundation
import CoreData

extension TodoEntity {
    var wrappedID: UUID {
        id ?? UUID()
    }
    
    var wrappedTitle: String {
        title ?? ""
    }
    
    var wrappedPerformedDate: Date {
        performedDate ?? Date()
    }
    
    var dueDateIsToday: Bool {
        Calendar.current.isDateInToday(wrappedPerformedDate)
    }
    
    var childrenArray: [TodoEntity] {
        (children as? Set<TodoEntity>)?.sorted(by: { $0.createdAt ?? Date() < $1.createdAt ?? Date() }) ?? []
    }
}
