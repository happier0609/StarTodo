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

    @State private var parentTitle: String = ""
    @State private var childTitles: [String] = [""]
    @State private var defaultMinutes: Int = 25

    var onComplete: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // 상위 카드
                VStack(alignment: .leading, spacing: 12) {
                    Text("상위 할 일")
                        .typo(.textSMEmphasized)
                        .foregroundColor(Color("Cool300"))

                    TextField("제목을 입력하세요", text: $parentTitle)
                        .padding(12)
                        .background(Color("Cool1000"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(Color("BgLight"))
                        .typo(.textMDRegular)
                }
                .padding(.horizontal)

                // 기본 시간
                HStack {
                    Text("기본 시간")
                        .typo(.textSMEmphasized)
                        .foregroundColor(Color("Cool300"))

                    Spacer()

                    Stepper(value: $defaultMinutes, in: 5...180, step: 5) {
                        Text("\(defaultMinutes)분")
                            .typo(.textMDEmphasized)
                            .foregroundColor(Color("BgLight"))
                    }
                }
                .padding()
                .background(Color("Cool1000"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                // 하위 카드
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("하위 할 일")
                            .typo(.textSMEmphasized)
                            .foregroundColor(Color("Cool300"))
                        Spacer()
                        Button {
                            childTitles.append("")
                        } label: {
                            Label("추가", systemImage: "plus.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(Color("Primary500"))
                                .typo(.textSMEmphasized)
                        }
                    }

                    ForEach(childTitles.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            TextField("할 일 \(i+1)", text: Binding(
                                get: { childTitles[i] },
                                set: { childTitles[i] = $0 }
                            ))
                            .padding(10)
                            .background(Color("Cool1000"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(Color("BgLight"))
                            .typo(.textMDRegular)

                            if childTitles.count > 1 {
                                Button(role: .destructive) {
                                    childTitles.remove(at: i)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(Color("Cool600"))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("Cool1000"))
                )
                .padding(.horizontal)

                // 저장 버튼
                Button(action: addParentTodo) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("추가하기")
                            .typo(.textMDEmphasized)
                    }
                    .foregroundColor(Color("White"))
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color("Primary500"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(parentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(parentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical, 16)
        }
        .background(Color("BgDark").ignoresSafeArea())
        .navigationTitle("할 일 만들기")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addParentTodo() {
        // 루트 order 계산
        let fd = FetchDescriptor<Todo>(predicate: #Predicate { $0.parent == nil })
        let roots = (try? modelContext.fetch(fd)) ?? []
        let nextOrder = (roots.map(\.order).max() ?? -1) + 1

        let parent = Todo(title: parentTitle,
                          isCompleted: false,
                          setTime: defaultMinutes,
                          elapsedTime: 0,
                          createdAt: .now,
                          performedDate: nil,
                          order: nextOrder,
                          parent: nil)

        var childOrder = 0
        for t in childTitles where !t.trimmingCharacters(in: .whitespaces).isEmpty {
            let child = Todo(title: t,
                             isCompleted: false,
                             setTime: defaultMinutes,
                             elapsedTime: 0,
                             createdAt: .now,
                             performedDate: nil,
                             order: childOrder,
                             parent: parent)
            childOrder += 1
            parent.children.append(child)
        }

        modelContext.insert(parent)
        try? modelContext.save()
        onComplete?()
    }
}
#Preview {
    MainView()
}
