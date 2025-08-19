//
//  MinutePickerChip.swift
//  StarTodo
//
//  Created by 조민경 on 8/19/25.
//

import SwiftUI

struct MinutePickerChip: View {
    @Binding var minutes: Int
    let options = Array(stride(from: 5, through: 30, by: 5)) // 5~30분, 5분 단위

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { m in
                Button {
                    minutes = m
                } label: {
                    HStack {
                        Text("\(m)분")
                        if m == minutes {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(minutes)분")
                    .font(.headline).bold()
                Image(systemName: "chevron.down")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color("Cool900"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
