//
//  AddTaskModalView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/25/25.
//

import SwiftUI
import SwiftData

/// 할 일을 새로 추가하거나 수정할 수 있는 모달 뷰
/// - 제목 입력 및 세부 항목(자식 할 일) 입력 가능
/// - 저장 로직은 ViewModel로 위임되어 있음 (MVVM 구조)
struct AddTaskModalView: View {
    
    /// 모달 표시 여부를 제어하는 바인딩
    @Binding var isPresented: Bool
    
    /// 수정하려는 기존 할 일 (없으면 새로 생성)
    var editingParent: Todo?
    
    /// SwiftData의 모델 컨텍스트 (삽입/삭제 등 DB 작업에 필요)
    @Environment(\.modelContext) private var context
    
    /// 상위 뷰에서 주입받는 ViewModel (AddList 전용)
    @EnvironmentObject private var viewModel: AddListViewModel
    
    /// 입력된 제목 (부모 할 일)
    @State private var title: String = ""
    
    /// 입력된 자식 할 일 목록 (문자열 배열)
    @State private var children: [String] = [""]
    
    /// 수정 모드인지 확인
    private var isEditMode: Bool {
        editingParent != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 네비게이션 바
                navigationBar
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 제목 입력 섹션
                        titleSection
                        
                        // 하위 작업 섹션
                        childrenSection
                    }
                    .padding()
                }
                
                // 저장 버튼
                saveButton
            }
        }
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            Button("취소") {
                isPresented = false
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Text(isEditMode ? "할 일 수정" : "새로운 할 일")
                .font(.headline)
            
            Spacer()
            
            // 빈 공간 유지용
            Text("취소")
                .opacity(0)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("제목")
                .font(.caption)
                .foregroundColor(.gray)
            
            TextField("예: A프로젝트: SNS 캠페인 이미지 제작", text: $title)
                .font(.headline)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Children Section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("하위 작업")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if isEditMode && !children.filter({ !$0.isEmpty }).isEmpty {
                    Text("\(children.filter({ !$0.isEmpty }).count)개")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(children.indices, id: \.self) { index in
                    childItemRow(at: index)
                }
                
                addChildButton
            }
        }
    }
    
    // MARK: - Child Item Row
    @ViewBuilder
    private func childItemRow(at index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .foregroundColor(.gray)
                .font(.system(size: 20))
            
            TextField("하위 작업 입력", text: $children[index])
                .textFieldStyle(.plain)
            
            // 삭제 버튼 (최소 1개는 유지)
            if children.count > 1 || !children[index].isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        removeChild(at: index)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    // MARK: - Add Child Button
    private var addChildButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                children.append("")
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("하위 작업 추가")
                    .font(.callout)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveChanges) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text(isEditMode ? "수정 완료" : "추가하기")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
            )
            .padding()
        }
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    // MARK: - Helper Methods
    private func loadExistingData() {
        if let todo = editingParent {
            title = todo.title
            
            // 기존 자식들을 불러옴
            let existingChildren = todo.children
                .sorted(by: { $0.order < $1.order })
                .map { $0.title }
            
            if !existingChildren.isEmpty {
                children = existingChildren
            } else {
                children = [""]
            }
        }
    }
    
    private func removeChild(at index: Int) {
        // 최소 1개의 빈 필드는 유지
        if children.count > 1 {
            children.remove(at: index)
        } else if !children[index].isEmpty {
            children[index] = ""
        }
    }
    
    private func saveChanges() {
        // 빈 문자열 필터링
        let filteredChildren = children.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        viewModel.saveTodo(
            editingParent: editingParent,
            title: title,
            children: filteredChildren,
            context: context
        )
        isPresented = false
    }
}
