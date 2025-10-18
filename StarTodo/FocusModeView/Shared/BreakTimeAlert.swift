//
//  BreakTimeAlert.swift
//  StarTodo
//
//  Created by 조민경 on 8/19/25.
//

import SwiftUI

struct BreakTimeAlert: View {
    @Binding var isPresented: Bool
    @Binding var minutes: Int
    let onConfirm: () -> Void
    
    private let options = Array(stride(from: 5, through: 30, by: 5))
    
    var body: some View {
        ZStack {
            // 🔹 Dim 배경 (탭 시 닫힘)
            Color("BgDark").opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring(response: 0.25)) {
                        isPresented = false
                    }
                }
            
            // 🔹 카드 알럿
            VStack(spacing: 4) {
                // 제목
                Text("잠깐 쉴까요?")
                    .typo(.titleMDemphasized)
                    .foregroundColor(Color("App.White"))
                
                // 설명
                Text("쉬는 시간을 설정해보세요.\n탐사를 다시 시작해야 할 때 알려드릴게요!")
                    .typo(.textSMRegular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("App.White"))
                
                // ▼ 버튼형 타임 피커
                MinutePickerChip(minutes: $minutes)
                    .padding(.top, 4)
                
                // 구분선
                Rectangle()
                    .fill(Color("App.White").opacity(0.08))
                    .frame(height: 1)
                    .padding(.top, 14)
                
                // ✅ 단일 버튼
                Button {
                    onConfirm()
                    withAnimation(.spring(response: 0.25)) {
                        isPresented = false
                    }
                } label: {
                    Text("휴식하기")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(Color("Primary500"))
                        .typo(.textMDEmphasized)
                }
            }
            .padding(.top, 20)
            .background(Color("Cool1000"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 60)
            .shadow(radius: 30)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// View 확장: isPresented가 true일 때만 오버레이 표시
extension View {
    func breakTimeAlert(isPresented: Binding<Bool>,
                        minutes: Binding<Int>,
                        onConfirm: @escaping () -> Void) -> some View {
        overlay {
            if isPresented.wrappedValue {
                BreakTimeAlert(isPresented: isPresented,
                               minutes: minutes,
                               onConfirm: onConfirm)
            }
        }
    }
}

#if DEBUG
import SwiftUI
// MARK: - Preview

#Preview("BreakTimeAlert - Preview") {
    StatefulPreviewWrapper(true) { isPresented in
        StatefulPreviewWrapper(10) { minutes in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 실제 Alert 뷰
                BreakTimeAlert(
                    isPresented: isPresented,
                    minutes: minutes,
                    onConfirm: {
                        print("✅ 휴식 시작 \(minutes.wrappedValue)분")
                    }
                )
            }
        }
    }
}

/// Preview에서 @State 바인딩 테스트를 쉽게 하기 위한 Wrapper
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ initialValue: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

#endif
