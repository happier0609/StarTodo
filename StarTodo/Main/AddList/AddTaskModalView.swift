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
/// 모달 높이는 medium ~ large 사이에서 확장되며,
/// 하위 작업 수에 따라 스크롤로 전환됨

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
    
    var body: some View {
        VStack(spacing: 16) {
            // 상단 입력 안내
            HStack {
                Text(editingParent == nil ? "여기에 새로운 할 일을 추가하세요." : "")
                    .foregroundColor(Color.gray)
                Spacer()
            }
            .padding(.top)
            
            // 제목 입력 필드
            TextField("예: A프로젝트: SNS 캠페인 이미지 제작", text: $title)
                .font(.headline)
                .padding(.vertical, 4)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            // 하위 항목 목록
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(children.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                            TextField("하위 작업 입력", text: $children[index])
                                .textFieldStyle(.plain)
                            if children.count > 1 {
                                Button(action: {
                                    children.remove(at: index)
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 하위 작업 추가 버튼
                    Button(action: {
                        children.append("")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("하위 작업 추가하기")
                        }
                        .font(.callout)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                }
            }
            
            Spacer()
            
            // 저장 버튼 (우측 하단 고정)
            HStack {
                Spacer()
                Button {
                    viewModel.saveTodo(
                        editingParent: editingParent,
                        title: title,
                        children: children,
                        context: context
                    )
                    isPresented = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(title.isEmpty ? .gray : .accentColor)
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .onAppear {
            if let todo = editingParent {
                title = todo.title
                children = todo.children
                    .sorted(by: { $0.order < $1.order })
                    .map { $0.title }
                
                if children.isEmpty {
                    children = [""]
                }
            }
        }
    }
}
