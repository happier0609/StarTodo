//
//  CustomSegmentedControl.swift
//  StarTodo
//
//  Created by 조민경 on 8/7/25.
//

import SwiftUI

enum FocusTab: String, CaseIterable {
    case timer = "타이머"
    case list = "목록"
}

struct CustomSegmentedControl: View {
    @Binding var selectedTab: FocusTab
    @Namespace private var animation

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color("Cool900"))

            HStack(spacing: 0) {
                ForEach(FocusTab.allCases, id: \.self) { tab in
                    ZStack {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("Warm400"))
                                .matchedGeometryEffect(id: "segment", in: animation)
                        }

                        Text(tab.rawValue)
                            .foregroundColor(Color("White"))
                            .typo(selectedTab == tab ? .textSMEmphasized : .textSMRegular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .contentShape(Rectangle()) // 탭 클릭 범위 확장
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .frame(width: 180, height: 40)
        .padding(.horizontal)
    }
}

struct ExampleView: View {
    @State private var selectedTab: FocusTab = .timer

    var body: some View {
        VStack {
            CustomSegmentedControl(selectedTab: $selectedTab)

            Spacer()

            Text("현재 선택: \(selectedTab.rawValue)")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    ExampleView()
}
