//
//  AddTaskModalView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 4/25/25.
//

import SwiftUI
import SwiftData

/// 할 일을 새로 추가하거나 수정할 수 있는 모달 뷰
struct AddTaskModalView: View {
    
    @Binding var isPresented: Bool
    let editingParent: Todo?
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var listViewModel: AddListViewModel
    @StateObject private var viewModel: AddTaskModalViewModel
    
    init(isPresented: Binding<Bool>, editingParent: Todo? = nil) {
        self._isPresented = isPresented
        self.editingParent = editingParent
        
        // ViewModel 초기화 - 실제 앱에서는 context와 listViewModel이 필요
        // 하지만 init에서는 접근 불가하므로 임시 객체 생성
        self._viewModel = StateObject(wrappedValue: AddTaskModalViewModel(
            editingParent: editingParent,
            parentViewModel: AddListViewModel(),
            context: defaultContext
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                navigationBar
                
                ScrollView {
                    VStack(spacing: 20) {
                        titleSection
                        childrenSection
                    }
                    .padding()
                }
                
                saveButton
            }
            .background(Color("BgLight").ignoresSafeArea())
        }
        .onAppear {
            // 실제 ViewModel 재설정
            viewModel.setupWithParent(listViewModel, context: context)
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            Button("취소") {
                isPresented = false
            }
            .foregroundColor(Color("Info300"))
            
            Spacer()
            
            Text(viewModel.modalTitle)
                .font(.headline)
            
            Spacer()
            
            Text("취소").opacity(0) // 균형 맞추기용
        }
        .padding()
        .background(Color("BgLight"))
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                if viewModel.childrenCount > 0 {
                    Image("List")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                TextField("여기에 새로운 할 일을 추가하세요", text: $viewModel.title)
                    .typo(.textMDRegular)
                    .padding()
            }
            .background(Color("App.White"))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Children Section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            childrenHeader
            
            VStack(spacing: 12) {
                ForEach(viewModel.children.indices, id: \.self) { index in
                    childItemRow(at: index)
                }
                
                addChildButton
            }
        }
    }
    
    private var childrenHeader: some View {
        HStack {
            if viewModel.isEditMode && viewModel.childrenCount > 0 {
                Text("\(viewModel.childrenCount)개")
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool200"))
            }
        }
    }
    
    @ViewBuilder
    private func childItemRow(at index: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle")
                .foregroundColor(.gray)
                .font(.system(size: 20))
            
            TextField("하위 작업 입력", text: $viewModel.children[index])
                .textFieldStyle(.plain)
                .typo(.textSMRegular)
            
            if viewModel.canRemoveChild(at: index) {
                Button(action: {
                    viewModel.removeChild(at: index)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("App.White"))
        .cornerRadius(10)
    }
    
    private var addChildButton: some View {
        Button(action: viewModel.addChild) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                Text("하위 작업 추가")
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool300"))
                Spacer()
            }
            .foregroundColor(Color("Primary600"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.leading, 12)
            .background(Color("App.White"))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            viewModel.save()
            isPresented = false
        }) {
            HStack {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
            }
            .padding(22)
        }
        .disabled(viewModel.isSaveDisabled)
    }
}

// MARK: - Preview
#if DEBUG
struct AddTaskModalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddTaskModalView(
                isPresented: .constant(true),
                editingParent: nil
            )
            .previewDisplayName("새 할 일 추가")
            
            AddTaskModalView(
                isPresented: .constant(true),
                editingParent: createSampleTodo()
            )
            .previewDisplayName("할 일 수정")
        }
        .environmentObject(AddListViewModel())
        .modelContainer(for: Todo.self, inMemory: true)
    }
    
    static func createSampleTodo() -> Todo {
        Todo(
            title: "A프로젝트: SNS 캠페인 이미지 제작",
            isCompleted: false,
            setTime: 25,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 0,
            parent: nil
        )
    }
}
#endif
