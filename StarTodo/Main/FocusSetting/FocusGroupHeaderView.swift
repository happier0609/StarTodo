//
//  FocusGroupHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/22/25.
//

import SwiftUI

struct FocusGroupHeaderView: View {
    let parent: Todo
    let selectedChildCount: Int
    let totalChildCount: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpand: () -> Void
    let onParentTap: () -> Void
    
    private var hasChildren: Bool { totalChildCount > 0 }
    
    /// ✅ 부모나 자식 중 하나라도 선택된 상태
    private var isActive: Bool {
        isSelected || selectedChildCount > 0
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggleExpand) {
                Image(isExpanded ? "Lists" : "List")
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)                // 기본 블루 하이라이트 제거
            .accessibilityLabel(isExpanded ? "그룹 접기" : "그룹 펼치기")
            
            
            // ▶ 부모 영역 전체를 버튼으로 처리 (제목 + 카운트)
            Button(action: onParentTap) {
                HStack {
                    Text(parent.title)
                        .typo(.textMDRegular)
                        .foregroundColor(isActive ? Color("Primary500") : Color("Cool300"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if hasChildren {
                        Text("\(selectedChildCount)/\(totalChildCount)")
                            .typo(.textMDRegular)
                            .foregroundColor(isActive ? Color("Primary500") : Color("Cool300"))
                    }
                }
                .contentShape(Rectangle())          // 라벨 내부도 전부 터치
            }
            .buttonStyle(.plain)
        }
        .padding(18)
    }
}

#if DEBUG
import SwiftUI
import SwiftData

#Preview("② 자식 2개 모두 선택됨") {
    let parent = Todo(title: "영어 공부", isCompleted: false)
    let child1 = Todo(title: "문법 복습", isCompleted: false, parent: parent)
    let child2 = Todo(title: "단어 외우기", isCompleted: false, parent: parent)
    parent.children.append(contentsOf: [child1, child2])
    
    return FocusGroupCardView(
        parent: parent,
        children: [child1, child2],
        isExpanded: true,
        selectedChildCount: 2,
        totalChildCount: 2,
        isSelected: true,
        onToggleExpand: {},
        onParentTap: {},
        onChildTap: { _ in }
    )
    .environmentObject(FocusSettingViewModel())
}

#endif
