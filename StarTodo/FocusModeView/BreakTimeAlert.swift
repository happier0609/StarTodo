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
            // Dim
            Color("Dark").opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)

            // Card
            VStack(spacing: 16) {
                Text("잠깐 쉴까요?")
                    .typo(.titleMDemphasized)
                    .foregroundColor(Color("White"))

                Text("쉬는 시간을 설정해보세요.\n탐사를 다시 시작해야 할 때 알려드릴게요!")
                    .typo(.textSMRegular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("White"))

                Picker("휴식 시간", selection: $minutes) {
                    ForEach(options, id: \.self) { m in
                        Text("\(m)분").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
                .clipped()

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            isPresented = false
                        }
                    } label: {
                        Text("취소")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("Cool900"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        onConfirm()
                        withAnimation(.spring(response: 0.25)) {
                            isPresented = false
                        }
                    } label: {
                        Text("휴식하기")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("Primary500"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(20)
            .background(Color("Cool1000"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
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
