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
                    .stroke(isSelected ? Color("Primary500") : Color("App.White"), lineWidth: 1.3)
            )
            .foregroundColor(isSelected ? Color("Primary500") : Color("Cool300"))
            .onTapGesture {
                focusSettingVM.toggleSelection(of: todo)
            }
    }
}

#if DEBUG
import SwiftUI

#Preview("✅ 선택되지 않은 항목") {
    let todo = Todo(title: "영어 단어 외우기", isCompleted: false)
    let vm = FocusSettingViewModel()
    
    return FocusItemRowView(todo: todo)
        .environmentObject(vm)
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("✅ 선택된 항목") {
    let todo = Todo(title: "수학 문제 풀기", isCompleted: false)
    let vm = FocusSettingViewModel()
    vm.isSelected(todo) // 선택된 상태로 만들기
    
    return FocusItemRowView(todo: todo)
        .environmentObject(vm)
        .padding()
        .previewLayout(.sizeThatFits)
}
#endif
