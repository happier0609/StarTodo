import SwiftUI
import SwiftData

struct TimerItemRowView: View {
    let item: Todo
    let parentTitle: String?          // 🧭 자식 항목일 경우 상단에 부모 제목 표시
    let selectedTime: Int?            // ⏱ 선택된 시간 (nil이면 '없음')
    let onTimeChange: (Int?) -> Void  // 🔁 시간 변경 시 호출되는 콜백

    // ⏱ 시간 선택 옵션: nil("없음") 포함, 5분~60분까지 5분 단위
    private let timeOptions: [Int?] = [nil] + Array(stride(from: 5, through: 60, by: 5))

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // 🧭 자식 항목일 경우 상단에 부모 제목 표시
            if let parentTitle {
                Text(parentTitle)
                    .typo(.textSMRegular)
                    .foregroundColor(Color("Cool400"))
            }

            HStack {
                // 🏷 할 일 제목
                Text(item.title)
                    .typo(.textMDRegular)
                    .foregroundColor(Color("Cool1100"))

                Spacer()

                // ⏱ 시간 선택 메뉴
                Menu {
                    ForEach(timeOptions, id: \.self) { minute in
                        Button(action: {
                            onTimeChange(minute)
                        }) {
                            Text(minuteText(minute))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(minuteText(selectedTime))
                            .typo(.textMDEmphasized)
                            .foregroundColor(selectedTime == nil ? Color("Cool300") : Color("Info700"))
                        
                        // 위아래 화살표 아이콘
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(selectedTime == nil ? Color("Cool300") : Color("Info700"))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(selectedTime == nil ? Color("Cool100") : Color("Primary100"))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color("BgLight"))
        .cornerRadius(10)
    }

    // ⏱ 시간 텍스트 변환 함수 (nil → 없음)
    private func minuteText(_ minute: Int?) -> String {
        minute.map { "\($0)분" } ?? "없음"
    }
}
