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
                    VStack(spacing:12) {
                        titleSection
                            .padding(.horizontal, 8)
                        childrenSection
                            .padding(.horizontal, 12)
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
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                if viewModel.childrenCount > 0 {
                    Image("List")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                ZStack(alignment: .leading) {
                    if viewModel.title.isEmpty {
                        Text("여기에 새로운 할 일을 추가하세요")
                            .foregroundColor(Color("Cool300"))
                            .typo(.textMDRegular)
                            .padding(8)
                    }
                    
                    TextField("", text: $viewModel.title)
                        .typo(.textMDRegular)
                        .foregroundColor(Color("Cool1100"))
                        .padding(8)
                }
            }
            //            .background(Color("App.White"))
            //            .cornerRadius(10)
        }
    }
    
    // MARK: - Children Section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.children.indices, id: \.self) { index in
                childItemRow(at: index)
                
            }
            addChildButton
        }
    }
    
    @ViewBuilder
    private func childItemRow(at index: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "circle")
                .foregroundColor(Color("Info1400"))
                .font(.system(size: 20))
            
            ZStack(alignment: .leading) {
                if viewModel.children[index].isEmpty {
                    Text("하위 작업 입력하기")
                        .foregroundColor(Color("Cool300"))
                        .typo(.textSMRegular)
                }
                
                TextField("", text: $viewModel.children[index])
                    .foregroundColor(Color("Cool1100"))
                    .typo(.textSMRegular)
            }
            
            if viewModel.canRemoveChild(at: index) {
                Button(action: {
                    viewModel.removeChild(at: index)
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        //        .background(Color("App.White"))
        //        .cornerRadius(10)
    }
    
    private var addChildButton: some View {
        Button(action: viewModel.addChild) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                Text("하위 작업 추가하기")
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool300"))
                Spacer()
            }
            .foregroundColor(Color("Primary600"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            //            .background(Color("App.White"))
            //            .cornerRadius(10)
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
                
                Image(viewModel.isSaveDisabled ? "DoneYet" : "Done")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
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
        // 상위 할 일 생성
        let parentTodo = Todo(
            title: "A프로젝트: SNS 캠페인 이미지 제작",
            isCompleted: false,
            setTime: 25,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 0,
            parent: nil
        )
        
        // 하위 할 일 1
        let child1 = Todo(
            title: "참고 이미지 수집하기",
            isCompleted: false,
            setTime: 10,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 0,
            parent: parentTodo
        )
        
        // 하위 할 일 2
        let child2 = Todo(
            title: "포토샵 레이아웃 잡기",
            isCompleted: false,
            setTime: 15,
            elapsedTime: 0,
            createdAt: .now,
            performedDate: nil,
            order: 1,
            parent: parentTodo
        )
        
        // 관계 설정
        parentTodo.children = [child1, child2]
        
        return parentTodo
    }
}
#endif
