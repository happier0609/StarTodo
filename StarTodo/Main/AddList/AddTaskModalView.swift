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
    
    var body: some View {
        NavigationView {
            Form {
                
                // MARK: - 제목 입력 필드
                Section(header: Text("할 일 제목")) {
                    TextField("예: 방 청소하기", text: $title)
                }

                // MARK: - 세부 항목 입력 필드
                Section(header: Text("세부 항목")) {
                    ForEach(children.indices, id: \.self) { index in
                        HStack {
                            TextField("세부 항목", text: $children[index])

                            // 항목이 2개 이상일 때만 삭제 버튼 활성화
                            if children.count > 1 {
                                Button(action: {
                                    children.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // 새로운 자식 항목 추가 버튼
                    Button(action: {
                        children.append("")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("세부 항목 추가")
                        }
                    }
                }
            }
            .navigationTitle(editingParent == nil ? "새로운 할 일" : "할 일 수정")

            // MARK: - 상단 툴바
            .toolbar {
                // 왼쪽: 취소 버튼
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }

                // 오른쪽: 저장 버튼
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        // 저장 로직은 ViewModel에 위임
                        viewModel.saveTodo(
                            editingParent: editingParent,
                            title: title,
                            children: children,
                            context: context
                        )
                        isPresented = false
                    }
                    // 제목이 비어있으면 저장 불가
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }

        // MARK: - 뷰 등장 시, 편집 모드일 경우 초기값 설정
        .onAppear {
            if let todo = editingParent {
                title = todo.title
                children = todo.children
                    .sorted(by: { $0.order < $1.order })
                    .map { $0.title }

                // 자식 항목이 없을 경우 기본 한 칸
                if children.isEmpty { children = [""] }
            }
        }
    }
}
