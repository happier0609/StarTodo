//
//  FocusGroupCardView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/11/25.
//

import Foundation
import SwiftData
import SwiftUI

struct FocusGroupCardView: View {
    let parent: Todo
    let children: [Todo]
    let isExpanded: Bool
    let selectedChildCount: Int
    let totalChildCount: Int
    let isSelected: Bool
    let onToggleExpand: () -> Void
    let onParentTap: () -> Void
    let onChildTap: (Todo) -> Void
    
    @EnvironmentObject var focusSettingVM: FocusSettingViewModel
    
    // 전체 선택 상태 여부
    var isFullySelected: Bool {
        totalChildCount > 0 && selectedChildCount == totalChildCount
    }

    // 일부만 선택된 상태 여부
    var isPartiallySelected: Bool {
        selectedChildCount > 0 && selectedChildCount < totalChildCount
    }
    
    var isParentSelected: Bool {
        focusSettingVM.isSelected(parent.id)
    }
    
    // 자식 일부라도 선택된 경우 true
    var hasPartialSelection: Bool {
        !parent.children.isEmpty && selectedChildCount > 0 && selectedChildCount < totalChildCount
    }

    // 자식이 없을 경우 부모 선택 상태
    var isGroupSelected: Bool {
        if parent.children.isEmpty {
            return isParentSelected
        } else {
            return isFullySelected
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(isGroupSelected ? Color("Primary100") : Color("App.White"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            (isFullySelected || hasPartialSelection) ? Color("Primary500") : Color.clear,
                            lineWidth: 1.3
                        )
                )
            
            VStack(spacing: 0) {
                FocusGroupHeaderView(
                    parent: parent,
                    selectedChildCount: selectedChildCount,
                    totalChildCount: totalChildCount,
                    isExpanded: isExpanded,
                    isSelected: isGroupSelected,  // ✨ isSelected → isGroupSelected로 변경
                    onToggleExpand: onToggleExpand,
                    onParentTap: onParentTap
                )
                
                if isExpanded && !children.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(children, id: \.id) { child in
                            FocusItemRowView(todo: child, isChild: true)
                                .padding(.leading, 20)
                                .onTapGesture {
                                    onChildTap(child)
                                }
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 18)
                }
            }
//            .padding(.horizontal, 18)
        }
    }
}

#if DEBUG
import SwiftUI

#Preview("① 자식이 없는 단일 부모 항목") {
    let parent = Todo(title: "혼자 있는 할 일", isCompleted: false)
    
    return FocusGroupCardView(
        parent: parent,
        children: [],
        isExpanded: false,
        selectedChildCount: 0,
        totalChildCount: 0,
        isSelected: false,
        onToggleExpand: {},
        onParentTap: {},
        onChildTap: { _ in }
    )
    .environmentObject(FocusSettingViewModel())
}

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

#Preview("③ 부모만 선택됨") {
    let parent = Todo(title: "운동 루틴", isCompleted: false)
    let child1 = Todo(title: "스트레칭", isCompleted: false, parent: parent)
    let child2 = Todo(title: "근력운동", isCompleted: false, parent: parent)
    parent.children.append(contentsOf: [child1, child2])

    return FocusGroupCardView(
        parent: parent,
        children: [child1, child2],
        isExpanded: true,
        selectedChildCount: 0,
        totalChildCount: 2,
        isSelected: true, // 부모만 선택되었을 때
        onToggleExpand: {},
        onParentTap: {},
        onChildTap: { _ in }
    )
    .environmentObject(FocusSettingViewModel())
}

#Preview("④ 자식 1개만 선택됨") {
    let parent = Todo(title: "코딩 공부", isCompleted: false)
    let child1 = Todo(title: "SwiftUI 복습", isCompleted: false, parent: parent)
    let child2 = Todo(title: "샘플 프로젝트", isCompleted: false, parent: parent)
    parent.children.append(contentsOf: [child1, child2])

    return FocusGroupCardView(
        parent: parent,
        children: [child1, child2],
        isExpanded: true,
        selectedChildCount: 1,
        totalChildCount: 2,
        isSelected: false,
        onToggleExpand: {},
        onParentTap: {},
        onChildTap: { _ in }
    )
    .environmentObject(FocusSettingViewModel())
}
#endif
