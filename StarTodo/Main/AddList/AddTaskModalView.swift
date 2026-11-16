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
            parentViewModel: AddListViewModel(context: defaultContext, mainViewModel: nil),
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
        .alert("하위 항목이 가득 찼어요!", isPresented: $viewModel.showChildLimitAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("하위 항목은 최대 \(AddTaskModalViewModel.maxChildren)개까지 입력 가능해요.")
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
#Preview("할 일 추가") {
    // 1. 인메모리 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Todo.self, configurations: config)
    let context = container.mainContext
    
    // 2. ViewModels 초기화
    let mainVM = MainViewModel(context: context)
    let addListVM = AddListViewModel(context: context, mainViewModel: mainVM)
    
    // 3. View 반환
    return AddTaskModalView(
        isPresented: .constant(true),
        editingParent: nil
    )
    .environmentObject(addListVM)
    .environmentObject(mainVM)
    .modelContainer(container)
    .previewDisplayName("할 일 추가")
}

#Preview("할 일 수정") {
    // 1. 인메모리 컨테이너 생성
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Todo.self, configurations: config)
    let context = container.mainContext
    
    // 2. ViewModels 초기화
    let mainVM = MainViewModel(context: context)
    let addListVM = AddListViewModel(context: context, mainViewModel: mainVM)
    
    // 3. 샘플 Todo 생성
    let sampleParent = Todo(
        title: "프로젝트 완성하기",
        isCompleted: false,
        setTime: 60,
        elapsedTime: 0,
        createdAt: .now,
        performedDate: nil,
        order: 0,
        parent: nil
    )
    
    // 자식 Todo들
    let child1 = Todo(
        title: "UI 디자인",
        isCompleted: false,
        setTime: 30,
        elapsedTime: 0,
        createdAt: .now,
        performedDate: nil,
        order: 0,
        parent: sampleParent
    )
    
    let child2 = Todo(
        title: "API 연동",
        isCompleted: false,
        setTime: 30,
        elapsedTime: 0,
        createdAt: .now,
        performedDate: nil,
        order: 1,
        parent: sampleParent
    )
    
    sampleParent.children = [child1, child2]
    
    // Context에 삽입
    context.insert(sampleParent)
    context.insert(child1)
    context.insert(child2)
    
    // 4. View 반환
    return AddTaskModalView(
        isPresented: .constant(true),
        editingParent: sampleParent
    )
    .environmentObject(addListVM)
    .environmentObject(mainVM)
    .modelContainer(container)
    .previewDisplayName("할 일 수정")
}

#Preview("할 일 수정 - 단일 항목") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Todo.self, configurations: config)
    let context = container.mainContext
    
    let mainVM = MainViewModel(context: context)
    let addListVM = AddListViewModel(context: context, mainViewModel: mainVM)
    
    // 자식이 없는 단일 할 일
    let singleTodo = Todo(
        title: "운동하기",
        isCompleted: false,
        setTime: 30,
        elapsedTime: 0,
        createdAt: .now,
        performedDate: nil,
        order: 0,
        parent: nil
    )
    
    context.insert(singleTodo)
    
    return AddTaskModalView(
        isPresented: .constant(true),
        editingParent: singleTodo
    )
    .environmentObject(addListVM)
    .environmentObject(mainVM)
    .modelContainer(container)
    .previewDisplayName("할 일 수정 - 단일")
}

// MARK: - 헬퍼 함수 (선택사항)

extension AddTaskModalView {
    static func createPreviewEnvironment() -> (ModelContainer, MainViewModel, AddListViewModel) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Todo.self, configurations: config)
        let context = container.mainContext
        let mainVM = MainViewModel(context: context)
        let addListVM = AddListViewModel(context: context, mainViewModel: mainVM)
        return (container, mainVM, addListVM)
    }
}
#endif
