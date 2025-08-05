//
//  FocusModeViewModel+Preview.swift
//  StarTodo
//
//  Created by 조민경 on 8/5/25.
//

extension FocusModeViewModel {
    static func previewInstance(context: NSManagedObjectContext) -> FocusModeViewModel {
        let todos = makePreviewTodos(context: context)
        
        let vm = FocusModeViewModel(todoIDPairs: todos.map {
            ($0.id ?? UUID(), Int($0.setTime))
        })
        return vm
    }
}
