//
//  FocusItemRowView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/22/25.
//

import SwiftUI
import Foundation

struct FocusItemRowView: View {
    let todo: Todo
    var isChild: Bool = true
    
    @EnvironmentObject var focusSettingVM: FocusSettingViewModel
    
    var isSelected: Bool {
        focusSettingVM.isSelected(todo.id)
    }
    
    var body: some View {
        Text(todo.title)
            .typo(.textMDRegular)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color("Primary100") : Color("App.White"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                        ? Color("Primary500")
                        : (isChild ? Color("Cool200") : Color("App.White")),
                        lineWidth: 1.3
                    )
            )
            .foregroundColor(isSelected ? Color("Primary500") : Color("Cool300"))
            .onTapGesture {
                focusSettingVM.toggleSelection(of: todo)
            }
    }
}

#if DEBUG
import SwiftUI

#Preview("✅ Child 항목") {
    let todo = Todo(title: "UI 디자인 완성하기", isCompleted: false)
    let vm = FocusSettingViewModel()
    return FocusItemRowView(todo: todo, isChild: true)
        .environmentObject(vm)
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("✅ 부모 항목") {
    let todo = Todo(title: "프로젝트 작업", isCompleted: false)
    let vm = FocusSettingViewModel()
    return FocusItemRowView(todo: todo, isChild: false)
        .environmentObject(vm)
        .padding()
        .previewLayout(.sizeThatFits)
}
#endif
