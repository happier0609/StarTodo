//
//  TodoGroupCardView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/11/25.
//

import SwiftUI

struct TodoGroupCardView: View {
    let parent: TodoEntity
    let children: [TodoEntity]
    let onToggle: (TodoEntity) -> Void
    let onLongPressEdit: (TodoEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 상위 항목
            HStack {
                Button(action: {
                    onToggle(parent)
                }) {
                    Image(parent.isCompleted ? "Check" : "noneCheck")
                        .foregroundColor(parent.isCompleted ? .gray.opacity(0.4) : .gray)
                        .animation(.easeInOut(duration: 0.2), value: parent.isCompleted)
                }
                Text(parent.wrappedTitle)
                    .typo(.textMDRegular)
                    .foregroundColor(parent.isCompleted ? .gray.opacity(0.4) : .primary)
                    .strikethrough(parent.isCompleted, color: .gray.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: parent.isCompleted)
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture().onEnded { _ in
                    onLongPressEdit(parent)
                }
            )

            // 하위 항목
            ForEach(children, id: \TodoEntity.objectID) { child in
                HStack {
                    Button(action: {
                        onToggle(child)
                    }) {
                        Image(child.isCompleted ? "Check" : "noneCheck")
                            .foregroundColor(child.isCompleted ? .gray.opacity(0.4) : .gray)
                            .animation(.easeInOut(duration: 0.2), value: child.isCompleted)
                    }
                    Text(child.wrappedTitle)
                        .font(.subheadline)
                        .foregroundColor(child.isCompleted ? .gray.opacity(0.4) : .primary)
                        .strikethrough(child.isCompleted, color: .gray.opacity(0.4))
                        .animation(.easeInOut(duration: 0.2), value: child.isCompleted)
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.white))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

#Preview {
    MainView()
}
