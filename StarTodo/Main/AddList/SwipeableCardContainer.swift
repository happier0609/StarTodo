//
//  SwipeableCardContainer.swift
//  StarTodo
//
//  Created by 조민경 on 10/1/25.
//

import SwiftUI

/// 스와이프하여 삭제할 수 있는 카드 컨테이너
/// 왼쪽으로 스와이프하면 삭제 버튼이 나타남
struct SwipeableCardContainer<Content: View>: View {
    @State private var offset: CGFloat = 0
    @State private var isDeletingIconVisible = false
    
    /// 삭제 버튼 탭 시 실행될 액션
    let onDelete: () -> Void
    
    /// 카드 콘텐츠
    let content: Content
    
    /// 스와이프 임계값 설정
    private let deleteThreshold: CGFloat = -100
    private let showIconThreshold: CGFloat = -50
    private let deleteButtonWidth: CGFloat = 80
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            deleteButtonBackground
            cardContent
        }
    }
    
    // MARK: - Delete Button Background
    private var deleteButtonBackground: some View {
        HStack {
            Spacer()
            
            Button(action: onDelete) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("삭제")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .frame(width: deleteButtonWidth)
            }
            .opacity(isDeletingIconVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isDeletingIconVisible)
        }
        .frame(height: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red)
                .opacity(isDeletingIconVisible ? 1 : 0)
        )
    }
    
    // MARK: - Card Content with Gesture
    private var cardContent: some View {
        content
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged(handleDragChange)
                    .onEnded(handleDragEnd)
            )
    }
    
    // MARK: - Gesture Handlers
    private func handleDragChange(_ value: DragGesture.Value) {
        // 왼쪽으로만 스와이프 가능
        if value.translation.width < 0 {
            offset = value.translation.width
            isDeletingIconVisible = offset < showIconThreshold
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // 충분히 스와이프했으면 삭제 버튼 표시
            if value.translation.width < deleteThreshold {
                offset = -deleteButtonWidth
                isDeletingIconVisible = true
            } else {
                // 원위치로 복귀
                resetPosition()
            }
        }
    }
    
    private func resetPosition() {
        offset = 0
        isDeletingIconVisible = false
    }
}
