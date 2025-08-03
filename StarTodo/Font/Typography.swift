//
//  Typography.swift
//  JPS_3
//
//  Created by ChoMinKyung on 7/21/25.
//

import SwiftUI

// MARK: - Font Extension
extension Font {
    static func pretendard(_ weight: Font.Weight, size: CGFloat) -> Font {
        .custom("Pretendard-\(weight.fontName)", size: size)
    }

    static func spartan(_ weight: Font.Weight, size: CGFloat) -> Font {
        .custom("Spartan-\(weight.fontName)", size: size)
    }
}

// MARK: - Font.Weight Extension
extension Font.Weight {
    var fontName: String {
        switch self {
        case .regular: return "Regular"
        case .semibold: return "SemiBold"
        case .bold: return "Bold"
        case .light: return "Light"
        default: return "Regular"
        }
    }
}

// MARK: - Typography Enum
enum Typo {
    case textSMEmphasized
    case textSMRegular
    case textMDEmphasized
    case textMDRegular
    case textLGEmphasized
    case textLGRegular
    case captionSMEmphasized
    case captionSMRegular
    case captionMDemphasized
    case captionMDRegular
    case titleMDemphasized
    case titleMDRegular
    case titleLGEmphasized
    case titleLGRegular
    case alarmTitle
    case alarmButton
    case textXSRegular
    case textXSEmphasized
    case spartanBold
    case spartanLight

    var style: (font: Font, letterSpacing: CGFloat, lineHeight: CGFloat, fontSize: CGFloat) {
        let size: CGFloat
        let font: Font

        switch self {
        case .spartanBold:
            size = 15
            font = .spartan(.bold, size: size)
        case .spartanLight:
            size = 15
            font = .spartan(.light, size: size)
        case .textSMEmphasized:
            size = 13
            font = .pretendard(.semibold, size: size)
        case .textSMRegular:
            size = 13
            font = .pretendard(.regular, size: size)
        case .textMDEmphasized:
            size = 16
            font = .pretendard(.semibold, size: size)
        case .textMDRegular:
            size = 16
            font = .pretendard(.regular, size: size)
        case .textLGEmphasized:
            size = 20
            font = .pretendard(.semibold, size: size)
        case .textLGRegular:
            size = 20
            font = .pretendard(.regular, size: size)
        case .captionSMEmphasized:
            size = 10
            font = .pretendard(.semibold, size: size)
        case .captionSMRegular:
            size = 10
            font = .pretendard(.regular, size: size)
        case .captionMDemphasized:
            size = 12
            font = .pretendard(.semibold, size: size)
        case .captionMDRegular:
            size = 12
            font = .pretendard(.regular, size: size)
        case .titleMDemphasized:
            size = 17
            font = .pretendard(.semibold, size: size)
        case .titleMDRegular:
            size = 17
            font = .pretendard(.regular, size: size)
        case .titleLGEmphasized:
            size = 30
            font = .pretendard(.semibold, size: size)
        case .titleLGRegular:
            size = 30
            font = .pretendard(.regular, size: size)
        case .alarmTitle:
            size = 38
            font = .pretendard(.bold, size: size)
        case .alarmButton:
            size = 24
            font = .pretendard(.semibold, size: size)
        case .textXSRegular:
            size = 15
            font = .pretendard(.regular, size: size)
        case .textXSEmphasized:
            size = 15
            font = .pretendard(.semibold, size: size)
        }

        let letterSpacing = size * -0.002 // -0.2%
        let lineHeight = size * 1.3 // 130%

        return (font, letterSpacing, lineHeight, size)
    }
}

// MARK: - Typography Modifier
struct TypographyModifier: ViewModifier {
    let typo: Typo

    func body(content: Content) -> some View {
        let style = typo.style
        content
            .font(style.font)
            .kerning(style.letterSpacing)
            .lineSpacing(style.lineHeight - style.fontSize)
    }
}

extension View {
    func typo(_ style: Typo) -> some View {
        self.modifier(TypographyModifier(typo: style))
    }
}
