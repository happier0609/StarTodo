//
//  AddListView_Preciews.swift
//  StarTodo
//
//  Created by ChoMinKyung on 8/27/25.
//

#if DEBUG
import SwiftData

struct AddListView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(
            for: Todo.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let repo = TodoRepository(context: container.mainContext)

        // 시드 데이터
        let p = Todo(title: "수학", setTime: 25, order: 0)
        container.mainContext.insert(p)

        return AddListView()
            .modelContainer(container)   // 인메모리 컨테이너 주입
            .environmentObject(repo)     // 레포 주입
    }
}
#endif
