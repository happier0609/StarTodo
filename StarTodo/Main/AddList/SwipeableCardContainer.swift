//
//  SwipeableCardContainer.swift
//  StarTodo
//
//  Created by 조민경 on 10/1/25.
//  Updated: 스크롤 우선순위 최적화
//

import SwiftUI

/// 스와이프하여 삭제할 수 있는 카드 컨테이너
/// 왼쪽으로 스와이프하면 삭제 버튼이 나타남
struct SwipeableCardContainer<Content: View>: View {
    @State private var offset: CGFloat = 0
    @State private var isDeletingIconVisible = false
    @State private var isDraggingHorizontally: Bool? = nil
    
    /// 삭제 버튼 탭 시 실행될 액션
    let onDelete: () -> Void
    
    /// 카드 콘텐츠
    let content: Content
    
    /// 스와이프 임계값 설정
    private let deleteThreshold: CGFloat = -100
    private let showIconThreshold: CGFloat = -50
    private let deleteButtonWidth: CGFloat = 58
    private let minimumDistance: CGFloat = 15      // ✅ 10 → 15 (우발적 감지 방지)
    private let directionThreshold: CGFloat = 2.0  // ✅ 1.5 → 2.0 (스크롤 우선)
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButtonBackground
            cardContent
        }
    }
    
    // MARK: - Delete Button Background
    private var deleteButtonBackground: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 15) // 카드와 삭제 버튼 사이 padding
            
            Button(action: onDelete) {
                VStack {
                    Spacer()
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(Color("Danger300"))
                    Spacer()
                }
                .frame(width: deleteButtonWidth)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("Danger100"))
                )
            }
        }
        .opacity(isDeletingIconVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isDeletingIconVisible)
        .allowsHitTesting(isDeletingIconVisible)
    }
    
    // MARK: - Card Content with Gesture
    private var cardContent: some View {
        content
            .offset(x: offset)
            .gesture( // ✅ highPriorityGesture 제거 - 스크롤과 동등하게
                DragGesture(minimumDistance: minimumDistance)
                    .onChanged(handleDragChange)
                    .onEnded(handleDragEnd)
            )
    }
    
    // MARK: - Gesture Handlers
    private func handleDragChange(_ value: DragGesture.Value) {
        let horizontalTranslation = value.translation.width
        let verticalTranslation = value.translation.height
        
        // ✅ 첫 드래그 시 방향 판단 (수평이 수직의 2.0배 이상일 때만 수평으로 인식)
        if isDraggingHorizontally == nil {
            let absHorizontal = abs(horizontalTranslation)
            let absVertical = abs(verticalTranslation)
            
            // 충분한 거리를 이동했을 때만 방향 판단
            if absHorizontal > minimumDistance || absVertical > minimumDistance {
                isDraggingHorizontally = absHorizontal > absVertical * directionThreshold
                
                if isDraggingHorizontally == true {
                    print("🔄 카드 스와이프 감지: H=\(absHorizontal), V=\(absVertical)")
                } else {
                    print("↕️ 스크롤 우선: H=\(absHorizontal), V=\(absVertical)")
                }
            }
        }
        
        // ✅ 수평 드래그가 확정된 경우에만 offset 적용
        guard isDraggingHorizontally == true else { return }
        
        // 왼쪽으로만 스와이프 가능, 최대값 제한
        if horizontalTranslation < 0 {
            offset = max(horizontalTranslation, -200)
            isDeletingIconVisible = offset < showIconThreshold
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        // ✅ 수평 드래그가 아니었으면 무시
        guard isDraggingHorizontally == true else {
            isDraggingHorizontally = nil
            return
        }
        
        let translation = value.translation.width
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // 충분히 스와이프했으면 삭제 버튼 표시
            if translation < deleteThreshold {
                offset = -(deleteButtonWidth + 15)
                isDeletingIconVisible = true
                print("🗑️ 삭제 버튼 표시")
            } else {
                // 원위치로 복귀
                resetPosition()
                print("↩️ 카드 원위치")
            }
        }
        
        // ✅ 상태 리셋
        isDraggingHorizontally = nil
    }
    
    private func resetPosition() {
        offset = 0
        isDeletingIconVisible = false
    }
}
