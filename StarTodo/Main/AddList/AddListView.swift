//
//  AddListView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/1/25.
//

import SwiftUI
import SwiftData
import Foundation

struct AddListView: View {
    @EnvironmentObject private var repo: TodoRepository
    
    @State private var showModal = false
    @State private var editingParent: Todo? = nil
    
    @State private var showAlert = false
    @State private var parentToDelete: Todo? = nil
    
    // 1) 정렬 없이 루트(부모만) 질의
    @Query(
        filter: #Predicate<Todo> { $0.parent == nil }
        // sort: []  ← 정렬은 생략
    )
    private var parents: [Todo]
    
    // 2) 공통 정렬 규칙 (미완료 → 완료 → order → createdAt)
    private var sortedParents: [Todo] {
        parents.sorted { a, b in
            // false(0) 먼저, true(1) 나중
            let left  = (a.isCompleted ? 1 : 0, a.order, a.createdAt)
            let right = (b.isCompleted ? 1 : 0, b.order, b.createdAt)
            return left < right
        }
    }
    
    // 섹션 분리(오늘/이전)
    private var todayParents: [Todo] {
        parents.filter { Calendar.current.isDateInToday($0.createdAt) }
    }
    private var previousParents: [Todo] {
        parents.filter { !Calendar.current.isDateInToday($0.createdAt) }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if parents.isEmpty {
                AddListEmptyView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !todayParents.isEmpty {
                            Text("오늘 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)
                            
                            todoSection(for: todayParents)
                        }
                        
                        if !previousParents.isEmpty {
                            Text("이전에 추가됨")
                                .typo(.captionMDRegular)
                                .foregroundColor(Color("Cool300"))
                                .padding(.horizontal)
                            
                            todoSection(for: previousParents)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                    
                    Text("오늘 완료한 일은 매일 오전 5시에 리셋됩니다.")
                        .typo(.captionMDRegular)
                        .foregroundColor(Color("Cool300"))
                }
                .transition(.move(edge: .leading))
            }
            
            addButton
        }
        // 새로 만들기 / 편집
        .sheet(isPresented: $showModal) {
            AddTaskModalView(isPresented: $showModal,   // ← 바인딩 전달
                             editingParent: editingParent)
            .environmentObject(repo)
        }
        // 삭제 확인
        .alert("정말 삭제할까요?", isPresented: $showAlert, presenting: parentToDelete) { p in
            Button("삭제", role: .destructive) {
                try? repo.delete(p)
            }
            Button("취소", role: .cancel) {}
        } message: { p in
            Text("\"\(p.title)\"과 관련된 모든 할 일이 함께 삭제됩니다.")
        }
    }
    
    // 플로팅 추가 버튼
    private var addButton: some View {
        Button {
            editingParent = nil
            showModal = true
        } label: {
            Image("addTodo")
                .padding()
        }
    }
    
    // 섹션 렌더
    @ViewBuilder
    private func todoSection(for list: [Todo]) -> some View {
        VStack(spacing: 16) {
            ForEach(list) { parent in
                TodoGroupCardView(
                    parent: parent,
                    children: parent.children.sorted { $0.order < $1.order },
                    onToggle: { item in
                        try? repo.toggle(item)                 // 완료 토글
                    },
                    onLongPressEdit: { _ in
                        editingParent = parent
                        showModal = true
                    }
                )
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if parent.children.isEmpty {
                            try? repo.delete(parent)
                        } else {
                            showDeleteAlert(for: parent)
                        }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func showDeleteAlert(for parent: Todo) {
        parentToDelete = parent
        showAlert = true
    }
}

#Preview {
    MainView()
}
