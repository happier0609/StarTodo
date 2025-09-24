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

struct ReportTimelineRowView: View {
    let type: ReportRowType
    let viewModel: ReportViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .typo(.textMDRegular)
                    .foregroundColor(titleColor)

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
                .fill(Color("White"))
                .frame(width: 24, height: 24)
                .shadow(color: Color("White").opacity(0.8), radius: 6))

        case .incompleted:
            return AnyView(Circle()
                .stroke(Color("Cool100"), lineWidth: 2)
                .frame(width: 24, height: 24))

        case .breakSession:
            return AnyView(
                ZStack {
                    Circle()
                        .fill(Color("Info200").opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: "pause.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("Info200"))
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
