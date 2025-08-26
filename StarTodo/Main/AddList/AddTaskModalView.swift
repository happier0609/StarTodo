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
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var minutes: Int = 25

    var parent: Todo? = nil
    var onAdded: ((Todo) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("할 일 추가")
                .typo(.textLGEmphasized)
                .foregroundColor(Color("BgLight"))

            TextField("제목을 입력하세요", text: $title)
                .padding(12)
                .background(Color("Cool1000"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(Color("BgLight"))
                .typo(.textMDRegular)

            HStack {
                Text("시간")
                    .typo(.textSMEmphasized)
                    .foregroundColor(Color("Cool300"))
                Spacer()
                Stepper("\(minutes)분", value: $minutes, in: 5...180, step: 5)
                    .foregroundColor(Color("BgLight"))
            }
            .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Button("취소") { dismiss() }
                    .typo(.textMDEmphasized)
                    .foregroundColor(Color("Cool300"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("Cool1000"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    let new = insertTodo()
                    onAdded?(new)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("추가")
                            .typo(.textMDEmphasized)
                    }
                    .foregroundColor(Color("White"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("Primary500"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("Cool900").opacity(0.9))
        )
        .padding(.horizontal, 24)
    }

    private func insertTodo() -> Todo {
        let order: Int
        if let parent {
            order = (parent.children.map(\.order).max() ?? -1) + 1
        } else {
            let fd = FetchDescriptor<Todo>(predicate: #Predicate { $0.parent == nil })
            let roots = (try? modelContext.fetch(fd)) ?? []
            order = (roots.map(\.order).max() ?? -1) + 1
        }

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
}

#Preview {
    MainView()
}
