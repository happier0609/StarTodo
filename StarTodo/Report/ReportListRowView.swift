//
//  ReportTimelineRowView.swift
//  StarTodo
//
//  Created by 조민경 on 9/24/25.
//

import SwiftUI

// 완료, 미완료, 휴식
enum ReportRowType {
    case completed(ReportItem)
    case incompleted(ReportItem)
    case breakSession(BreakSession)
}

struct ReportListRowView: View {
    let type: ReportRowType
    let viewModel: ReportViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
                .padding(.top, 2)

            HStack {
                Text(title)
                    .typo(.textMDRegular)
                    .foregroundColor(titleColor)
                
                Spacer()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .typo(.textSMEmphasized)
                        .foregroundColor(subtitleColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var icon: some View {
        switch type {
        case .completed:
            return AnyView(Circle()
                .fill(Color("App.White"))
                .frame(width: 20, height: 20)
                .shadow(color: Color("App.White").opacity(0.8), radius: 6))

        case .incompleted:
            return AnyView(Circle()
                .stroke(Color("Cool100"), lineWidth: 2)
                .frame(width: 20, height: 20))

        case .breakSession:
            return AnyView(
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 20)
                }
            )
        }
    }

    private var title: String {
        switch type {
        case .completed(let todo), .incompleted(let todo):
            return todo.title
        case .breakSession:
            return "휴식"
        }
    }

    private var titleColor: Color {
        switch type {
        case .completed:
            return Color("BgLight")
        case .incompleted:
            return Color("Cool100")
        case .breakSession:
            return Color("Info200")
        }
    }

    private var subtitle: String? {
        switch type {
        case .completed(let todo):
            return viewModel.timeDescription(for: todo)
        case .incompleted:
            return nil
        case .breakSession(let session):
            return viewModel.breakDescription(for: session)
        }
    }

    private var subtitleColor: Color {
        switch type {
        case .breakSession(let session):
            return session.isOverdue ? Color("Warning200") : Color("Cool100")
        default:
            return Color("Info200")
        }
    }
}
