//
//  FocusGroupHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/22/25.
//

import SwiftUI

struct FocusGroupHeaderView: View {
    let parent: TodoEntity
    let selectedChildCount: Int
    let totalChildCount: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpand: () -> Void
    let onParentTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            // 토글 버튼만 독립적으로 동작
            if totalChildCount > 0 {
                Button(action: {
                    onToggleExpand()
                }) {
                    Image(isExpanded ? "Lists" : "List")
                }
            }
            
            // 🔹 할 일 제목 (왼쪽 정렬)
            Text(parent.title ?? "")
                .typo(.textMDRegular)
                .foregroundColor(isSelected ? Color("Primary500") : Color("Cool300"))
                .padding(.leading, 4)
            
            Spacer()
            
            // 🔹 선택 개수 표시 (오른쪽)
            if totalChildCount > 0 {
                Text("\(selectedChildCount)/\(totalChildCount)")
                    .typo(.textMDRegular)
                    .foregroundColor(isSelected ? Color("Primary500") : Color("Cool300"))
                
            }
        }
        .padding()
        // ✅ 이 부분은 버튼 바깥 영역만 동작하게!
        .contentShape(Rectangle()) // 전체 터치 인식 영역 지정
        .onTapGesture {
            onParentTap()
        }
    }
}
