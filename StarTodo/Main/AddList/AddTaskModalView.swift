//
//  AddTaskModalView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/25/25.
//

import SwiftUI
import SwiftData

struct AddTaskModalView: View {
    @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var repo: TodoRepository
        @Environment(\.modelContext) private var modelContext
        
        @Binding var isPresented: Bool
        var editingParent: Todo?   // nil이면 새로 추가, 있으면 편집
        
        @State private var parentTitle: String = ""
        @State private var childTasks: [String] = []
        
        // ✅ shake 관련
        @State private var shakeOffset: CGFloat = 0
        @State private var shouldShake: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                Text(editingParent == nil ? "할 일 추가" : "할 일 수정")
                    .typo(.textMDEmphasized)
                
                // ✅ 제목 + List 아이콘 조건부 표시
                HStack(spacing: 8) {
                    if !childTasks.filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }).isEmpty {
                        Image("List")
                            .resizable()
                            .frame(width: 18, height: 18)
                    }
                    TextField("여기에 새로운 할 일을 추가하세요.", text: $parentTitle)
                        .typo(.textMDRegular)
                        .foregroundStyle(Color("Cool300"))
                }
                
                // ✅ 하위 작업 리스트
                ForEach(Array(childTasks.enumerated()), id: \.offset) { index, task in
                    HStack(spacing: 8) {
                        Image("noneCheck")
                            .foregroundColor(Color("Primary500"))
                        
                        TextField("하위 작업 추가하기", text: $childTasks[index])
                            .typo(.textSMRegular)
                            .foregroundStyle(Color("Cool300"))
                            .frame(maxWidth: .infinity)
                            .layoutPriority(1) // 🔥 핵심
                        
                        Button(action: {
                            childTasks.remove(at: index)
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                
                Button(action: {
                    childTasks.append("")
                }) {
                    Label("하위 작업 추가하기", systemImage: "plus")
                        .typo(.textSMRegular)
                        .foregroundColor(Color("Primary600"))
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                if let p = editingParent {
                    parentTitle = p.title
                    childTasks  = p.children.map(\.title)
                }
            }
            
            // ✅ 플로팅 완료 버튼 (에셋 + Shake)
            Button(action: {
                let trimmed = parentTitle.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    // 👇 흔들기 트리거
                    withAnimation(.default) {
                        shakeOffset = 10
                        shouldShake.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            shakeOffset = 0
                        }
                    }
                    return
                }
                
                let trimmedChildren = childTasks.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                
                if let todo = editingTodo {
                    viewModel.updateParentTodo(todo, newTitle: trimmed, newChildren: trimmedChildren)
                } else {
                    viewModel.addParentTodo(with: trimmed, childTitles: trimmedChildren)
                }
                
                isPresented = false
            }) {
                Image(parentTitle.trimmingCharacters(in: .whitespaces).isEmpty ? "DoneYet" : "Done")
                    .resizable()
                    .frame(width: 56, height: 56)
            }
            .offset(x: shakeOffset * (shouldShake ? -1 : 1))
            .padding()
        }
    }
}

#Preview {
    MainView()
}
