//
//  TodoGroupCardView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/11/25.
//

import SwiftUI

struct TodoGroupCardView: View {
    let parent: Todo
    let children: [Todo]
    let onToggle: (Todo) -> Void
    let onLongPressEdit: (Todo) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 상위 항목
            parentSection
            
            // 하위 항목
            ForEach(children, id: \.id) { child in
                childItem(child)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.white))
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                isPressed = pressing
                if pressing {
                    // 햅틱 피드백 추가
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            },
            perform: {
                onLongPressEdit(parent)
            }
        )
    }
    
    // MARK: - Parent Section
    private var parentSection: some View {
        HStack {
            Button(action: {
                onToggle(parent)
                // 체크박스 햅틱 피드백
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(parent.isCompleted ? "Check" : "noneCheck")
                    .foregroundColor(parent.isCompleted ? .gray.opacity(0.4) : .gray)
                    .animation(.easeInOut(duration: 0.2), value: parent.isCompleted)
            }
            
            Text(parent.title)
                .typo(.textMDRegular)
                .foregroundColor(parent.isCompleted ? .gray.opacity(0.4) : .primary)
                .strikethrough(parent.isCompleted, color: .gray.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: parent.isCompleted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Child Item
    @ViewBuilder
    private func childItem(_ child: Todo) -> some View {
        HStack {
            Button(action: {
                onToggle(child)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Image(child.isCompleted ? "Check" : "noneCheck")
                    .foregroundColor(child.isCompleted ? .gray.opacity(0.4) : .gray)
                    .animation(.easeInOut(duration: 0.2), value: child.isCompleted)
            }
            
            Text(child.title)
                .font(.subheadline)
                .foregroundColor(child.isCompleted ? .gray.opacity(0.4) : .primary)
                .strikethrough(child.isCompleted, color: .gray.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: child.isCompleted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.leading, 16)
    }
}

#Preview {
    VStack(spacing: 16) {
        // 미완료 상태 프리뷰
        TodoGroupCardView(
            parent: Todo(
                title: "A프로젝트: SNS 캠페인",
                isCompleted: false,
                setTime: 25,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: nil,
                order: 0,
                parent: nil
            ),
            children: [
                Todo(
                    title: "이미지 디자인",
                    isCompleted: false,
                    setTime: 25,
                    elapsedTime: 0,
                    createdAt: .now,
                    performedDate: nil,
                    order: 0,
                    parent: nil
                ),
                Todo(
                    title: "카피라이팅",
                    isCompleted: true,
                    setTime: 25,
                    elapsedTime: 0,
                    createdAt: .now,
                    performedDate: .now,
                    order: 1,
                    parent: nil
                )
            ],
            onToggle: { _ in },
            onLongPressEdit: { _ in }
        )
        
        // 완료 상태 프리뷰
        TodoGroupCardView(
            parent: Todo(
                title: "회의 준비",
                isCompleted: true,
                setTime: 25,
                elapsedTime: 0,
                createdAt: .now,
                performedDate: .now,
                order: 0,
                parent: nil
            ),
            children: [],
            onToggle: { _ in },
            onLongPressEdit: { _ in }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
