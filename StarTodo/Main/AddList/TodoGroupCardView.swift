//
//  TodoGroupCardView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/11/25.
//

import SwiftUI
import SwiftData

struct TodoGroupCardView: View {
    @Environment(\.modelContext) private var modelContext

    let parent: Todo
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack(spacing: 12) {
                Text(parent.title)
                    .typo(.textLGEmphasized)
                    .foregroundColor(Color("BgLight"))

                Spacer()

                Button {
                    onEdit?()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color("Cool300"))
                }

                Button(role: .destructive) {
                    modelContext.delete(parent)
                    try? modelContext.save()
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color("Cool300"))
                }
            }

            // 자식 리스트
            VStack(spacing: 8) {
                ForEach(parent.children.sorted(by: { $0.order < $1.order })) { child in
                    HStack(spacing: 12) {
                        // 체크 모양 (보기용)
                        Circle()
                            .stroke(child.isCompleted ? Color("Cool600") : Color("Cool300"), lineWidth: 2)
                            .frame(width: 18, height: 18)

                        Text(child.title)
                            .foregroundColor(child.isCompleted ? Color("Cool600") : Color("BgLight"))
                            .typo(.textMDRegular)

                        Spacer()

                        // 시간 배지
                        Text("\(child.setTime)분")
                            .typo(.textSMEmphasized)
                            .foregroundColor(Color("BgLight"))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color("Cool900"))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(Color("Cool1000"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MainView()
}
