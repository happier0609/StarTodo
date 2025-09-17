//
//  MainVMBox.swift
//  StarTodo
//
//  Created by 조민경 on 9/17/25.
//

import SwiftData
import Combine

/// ⭐️ MainViewModel을 한번만 생성해서 여러 뷰에서 공유하기 위한 박스 (Box 객체)
final class MainVMBox: ObservableObject {
    @Published private(set) var vm: MainViewModel?

    /// 이미 있으면 그대로 두고, 없으면 새로 생성해서 할당
    @MainActor
    func setIfNeeded(with mc: ModelContext) {
        guard vm == nil else { return }
        vm = MainViewModel(context: mc)
    }
}
