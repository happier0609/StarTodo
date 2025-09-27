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
    
    var isParentSelected: Bool {
        focusSettingVM.isSelected(parent.id)
    }
    
    var isGroupSelected: Bool {
        isParentSelected || selectedChildCount > 0
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color("Primary100") : Color("App.White"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color("Primary500") : Color.clear, lineWidth: 1.3)
                )
            
            VStack(spacing: 0) {
                FocusGroupHeaderView(
                    parent: parent,
                    selectedChildCount: selectedChildCount,
                    totalChildCount: totalChildCount,
                    isExpanded: isExpanded,
                    isSelected: isSelected,
                    onToggleExpand: onToggleExpand,
                    onParentTap: onParentTap
                )
//                .padding(.bottom, isExpanded && !children.isEmpty ? 12 : 0)
                
                if isExpanded {
                    VStack(spacing: 10) {
                        ForEach(children, id: \.id) { child in
                            FocusItemRowView(todo: child, isChild: true)
                                .padding(.leading, 20)
                                .onTapGesture {
                                    onChildTap(child)
                                }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview {
    let parent = Todo(
        id: UUID(),
        title: "상위 할일",
        isCompleted: false,
        createdAt: Date(),
        order: 0
    )

    let children = [
        Todo(
            id: UUID(),
            title: "하위 할일 1",
            isCompleted: false,
            createdAt: Date(),
            order: 1,
            parent: parent
        ),
        Todo(
            id: UUID(),
            title: "하위 할일 2",
            isCompleted: true,
            createdAt: Date(),
            order: 2,
            parent: parent
        )
    ]
    
    FocusGroupCardView(
        parent: parent,
        children: children,
        isExpanded: true,
        selectedChildCount: 1,
        totalChildCount: 2,
        isSelected: true,
        onToggleExpand: {},
        onParentTap: {},
        onChildTap: { _ in }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
