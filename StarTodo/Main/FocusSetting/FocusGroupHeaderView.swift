//
//  FocusGroupHeaderView.swift
//  JPS_3
//
//  Created by ChoMinKyung on 5/22/25.
//

import SwiftUI

struct FocusGroupHeaderView: View {
    let parent: Todo
    let selectedChildCount: Int
    let totalChildCount: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpand: () -> Void
    let onParentTap: () -> Void

    private var hasChildren: Bool { totalChildCount > 0 }

    var body: some View {
        HStack(spacing: 12) {
            // ▼ 펼치기/접기 토글 (자식 있을 때만)
            if hasChildren {
                Button(action: onToggleExpand) {
                    Image(isExpanded ? "Lists" : "List")
                        .padding(8)                  // 터치 영역 확대
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)                // 기본 블루 하이라이트 제거
                .accessibilityLabel(isExpanded ? "그룹 접기" : "그룹 펼치기")
            } else {
                // 자식이 없다면 정렬 유지용 투명 공간 (아이콘 폭과 비슷하게)
                Color.clear.frame(width: 28, height: 28)
            }

            // ▶ 부모 영역 전체를 버튼으로 처리 (제목 + 카운트)
            Button(action: onParentTap) {
                HStack {
                    Text(parent.title)              // title은 non-optional
                        .typo(.textMDRegular)
                        .foregroundColor(isSelected ? Color("Primary500")
                                                   : Color("Cool300"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasChildren {
                        Text("\(selectedChildCount)/\(totalChildCount)")
                            .typo(.textMDRegular)
                            .foregroundColor(isSelected ? Color("Primary500")
                                                       : Color("Cool300"))
                    }
                }
                .contentShape(Rectangle())          // 라벨 내부도 전부 터치
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#if DEBUG
import SwiftUI
import SwiftData

#Preview("기본") {
    // ✅ 1. 단일 부모 (자식 없음)
    FocusGroupHeaderView(
        parent: Todo(title: "단일 할 일"),
        selectedChildCount: 0,
        totalChildCount: 0,
        isExpanded: false,
        isSelected: false,
        onToggleExpand: {},
        onParentTap: {}
    )
    .previewLayout(.sizeThatFits)
    .padding()
}

#Preview("자식 3개 중 2개 선택 (펼침)") {
    // ✅ 2. 부모 + 자식 3개, 일부 선택된 상태
    FocusGroupHeaderView(
        parent: Todo(title: "프로젝트 A"),
        selectedChildCount: 2,
        totalChildCount: 3,
        isExpanded: true,
        isSelected: true,
        onToggleExpand: {},
        onParentTap: {}
    )
    .previewLayout(.sizeThatFits)
    .padding()
    .background(Color("BgLight"))
}

#Preview("자식 3개 중 0개 선택 (닫힘)") {
    // ✅ 3. 부모 + 자식 3개, 아직 선택 안 됨
    FocusGroupHeaderView(
        parent: Todo(title: "SNS 캠페인 준비"),
        selectedChildCount: 0,
        totalChildCount: 3,
        isExpanded: false,
        isSelected: false,
        onToggleExpand: {},
        onParentTap: {}
    )
    .previewLayout(.sizeThatFits)
    .padding()
    .background(Color("BgLight"))
}
#endif
