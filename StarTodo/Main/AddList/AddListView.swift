//
//  AddListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import SwiftData

struct AddListView: View {
    @Environment(\.modelContext) private var modelContext

    // 입력 상태
    @State private var parentTitle: String = ""
    @State private var childTitles: [String] = [""]
    @State private var defaultMinutes: Int = 25

    // 저장 후 닫기
    var onComplete: (() -> Void)?

    var body: some View {
        Form {
            Section("상위 할 일") {
                TextField("제목", text: $parentTitle)
                Stepper("기본 시간 \(defaultMinutes)분", value: $defaultMinutes, in: 5...180, step: 5)
            }

            Section("하위 할 일") {
                ForEach(childTitles.indices, id: \.self) { i in
                    TextField("하위 제목", text: Binding(
                        get: { childTitles[i] },
                        set: { childTitles[i] = $0 }
                    ))
                }
                Button {
                    childTitles.append("")
                } label: { Label("하위 항목 추가", systemImage: "plus.circle") }
            }

            Section {
                Button {
                    addParentTodo()
                    onComplete?()
                } label: {
                    Text("추가하기").frame(maxWidth: .infinity)
                }
                .disabled(parentTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("할 일 추가")
    }

    private func addParentTodo() {
        let parent = Todo(title: parentTitle,
                          isCompleted: false,
                          setTime: defaultMinutes,
                          elapsedTime: 0,
                          createdAt: .now,
                          performedDate: nil,
                          order: nextRootOrder(),
                          parent: nil)

        // 비어있지 않은 자식만 추가
        for (idx, t) in childTitles.enumerated() where !t.trimmingCharacters(in: .whitespaces).isEmpty {
            let child = Todo(title: t,
                             isCompleted: false,
                             setTime: defaultMinutes,
                             elapsedTime: 0,
                             createdAt: .now,
                             performedDate: nil,
                             order: idx,
                             parent: parent)
            parent.children.append(child)
        }

        modelContext.insert(parent)
        try? modelContext.save()
    }

    /// 루트 목록의 다음 order (간단 버전)
    private func nextRootOrder() -> Int {
        // 큰 화면에서 @Query를 받도록 바꾸면 더 깔끔하지만,
        // 여기서는 간단히 현재 컨텍스트에서 루트만 fetch
        let fd = FetchDescriptor<Todo>(predicate: #Predicate { $0.parent == nil })
        let roots = (try? modelContext.fetch(fd)) ?? []
        return (roots.map(\.order).max() ?? -1) + 1
    }
}
