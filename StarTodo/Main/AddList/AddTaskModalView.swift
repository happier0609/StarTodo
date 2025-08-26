//
//  AddTaskModalView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/25/25.
//

import SwiftUI
import SwiftData

struct AddTaskModalView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var minutes: Int = 25
    var parent: Todo? = nil               // 특정 상위에 바로 추가하고 싶을 때 주입
    var onAdded: ((Todo) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("할 일 추가").font(.headline)

            TextField("할 일 제목", text: $title)
                .textFieldStyle(.roundedBorder)

            Stepper("시간 \(minutes)분", value: $minutes, in: 5...180, step: 5)

            HStack {
                Button("취소") {
                    dismiss()
                }
                Spacer()
                Button("추가") {
                    let t = insertTodo()
                    onAdded?(t)
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    @Environment(\.dismiss) private var dismiss

    private func insertTodo() -> Todo {
        let order = nextOrder(in: parent)
        let todo = Todo(title: title,
                        isCompleted: false,
                        setTime: minutes,
                        elapsedTime: 0,
                        createdAt: .now,
                        performedDate: nil,
                        order: order,
                        parent: parent)
        modelContext.insert(todo)
        try? modelContext.save()
        return todo
    }

    private func nextOrder(in parent: Todo?) -> Int {
        if let parent {
            return (parent.children.map(\.order).max() ?? -1) + 1
        } else {
            let fd = FetchDescriptor<Todo>(predicate: #Predicate { $0.parent == nil })
            let roots = (try? modelContext.fetch(fd)) ?? []
            return (roots.map(\.order).max() ?? -1) + 1
        }
    }
}

#Preview {
    MainView()
}
