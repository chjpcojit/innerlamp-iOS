//
//  ILTypography.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public enum ILTypography {
    
    // MARK: - Font Family Names
    public static let loraRegularName = "Lora-Regular"
    public static let loraMediumName = "Lora-Medium"
    public static let loraSemiBoldName = "Lora-SemiBold"
    public static let loraBoldName = "Lora-Bold"
    
    public static let beVietnamProRegularName = "BeVietnamPro-Regular"
    public static let beVietnamProMediumName = "BeVietnamPro-Medium"
    public static let beVietnamProSemiBoldName = "BeVietnamPro-SemiBold"
    public static let beVietnamProBoldName = "BeVietnamPro-Bold"
    
    // MARK: - Font Resolvers with Fallback
    
    /// Font Lora (Serif) dùng cho tiêu đề màn, kinh văn, số lớn
    public static func lora(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = loraBoldName
        case .semibold:
            fontName = loraSemiBoldName
        case .medium:
            fontName = loraMediumName
        default:
            fontName = loraRegularName
        }
        
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        }
        
        // Fallback to system serif font if custom font file is not present in bundle
        let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
    
    /// Font Be Vietnam Pro (Sans-serif) dùng cho UI, body, labels, buttons
    public static func beVietnamPro(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = beVietnamProBoldName
        case .semibold:
            fontName = beVietnamProSemiBoldName
        case .medium:
            fontName = beVietnamProMediumName
        default:
            fontName = beVietnamProRegularName
        }
        
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        }
        
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    // MARK: - Preset Styles
    
    // Display & Scripture (Lora Serif)
    public static let displayLarge = lora(size: 30, weight: .regular)
    public static let displayMedium = lora(size: 26, weight: .regular)
    public static let scriptureTitle = lora(size: 22, weight: .regular)
    public static let scriptureBodyLarge = lora(size: 20, weight: .regular)
    public static let scriptureBody = lora(size: 18, weight: .regular)
    public static let scriptureBodySmall = lora(size: 15, weight: .regular)

    // Splash / Onboarding intro (Lora Serif)
    public static let introDisplay = lora(size: 40, weight: .regular)
    public static let stepTitle = lora(size: 32, weight: .regular)
    /// Tiêu đề màn xác thực (Đăng ký, OTP, Đăng nhập...) — 29px Lora theo design handoff.
    public static let authTitle = lora(size: 29, weight: .regular)
    /// Dòng phụ đề chữ nghiêng dưới wordmark/tiêu đề — luôn dùng cùng `.italic()` ở nơi gọi.
    public static let taglineItalic = lora(size: 14, weight: .regular)
    /// Wordmark "InnerLamp" màn Splash — 34px Lora theo design handoff.
    public static let splashWordmark = lora(size: 34, weight: .regular)
    /// Slogan nghiêng dưới wordmark màn Splash — 15px Lora, luôn dùng cùng `.italic()` ở nơi gọi.
    public static let splashTagline = lora(size: 15, weight: .regular)
    
    // Body & UI (Be Vietnam Pro Sans-serif)
    public static let eyebrow = beVietnamPro(size: 10, weight: .semibold)
    public static let captionSmall = beVietnamPro(size: 9.5, weight: .medium)
    public static let caption = beVietnamPro(size: 10.5, weight: .regular)
    public static let label = beVietnamPro(size: 11, weight: .regular)
    public static let subhead = beVietnamPro(size: 11.5, weight: .regular)
    public static let subheadMedium = beVietnamPro(size: 11.5, weight: .medium)
    public static let chip = beVietnamPro(size: 12, weight: .medium)
    public static let bodySmall = beVietnamPro(size: 12.5, weight: .regular)
    public static let bodySmallMedium = beVietnamPro(size: 12.5, weight: .medium)
    public static let sectionTitle = beVietnamPro(size: 13, weight: .medium)
    public static let body = beVietnamPro(size: 13.5, weight: .regular)
    public static let button = beVietnamPro(size: 13.5, weight: .medium)
    public static let headerTitle = beVietnamPro(size: 13.5, weight: .medium)
    public static let bodyLarge = beVietnamPro(size: 14, weight: .regular)
    public static let rowTitle = beVietnamPro(size: 14, weight: .medium)
    public static let title2 = beVietnamPro(size: 16, weight: .semibold)
    public static let title1 = beVietnamPro(size: 18, weight: .semibold)
    /// Chữ số trong ô nhập mã OTP — 21px medium theo design handoff.
    public static let otpDigit = beVietnamPro(size: 21, weight: .medium)

    /// Ghi chú / mô tả phụ 12px regular (vd. dòng phụ dưới số lớn ở thẻ "Đang cùng ngồi thiền")
    public static let note = beVietnamPro(size: 12, weight: .regular)
    /// Đoạn văn ngắn 13px, luôn dùng cùng `lineHeightMultiple` ~1.6 ở nơi gọi
    public static let bodyCompact = beVietnamPro(size: 13, weight: .regular)
    /// Số thống kê lớn 38px (vd. số người đang cùng ngồi thiền)
    public static let statNumber = beVietnamPro(size: 38, weight: .regular)
    /// Mũi tên "›" ở cuối hàng/thẻ điều hướng
    public static let chevron = beVietnamPro(size: 18, weight: .regular)
    /// Số thống kê vừa 22px medium (vd. "168 giờ tu tập" ở thẻ 3 ô số liệu)
    public static let statValue = beVietnamPro(size: 22, weight: .medium)
    /// Chú thích rất nhỏ 10px regular (vd. dòng phụ dưới tên dấu ấn)
    public static let microCaption = beVietnamPro(size: 10, weight: .regular)
    /// Nhãn thứ trong tuần ở đầu lưới lịch tháng — 10.5px medium
    public static let captionMedium = beVietnamPro(size: 10.5, weight: .medium)
    /// Số ngày âm nhỏ dưới số ngày dương trong ô lịch tháng — 8.5px regular
    public static let calendarLunarDay = beVietnamPro(size: 8.5, weight: .regular)
    /// Câu chia sẻ ngắn dạng trích dẫn: Lora 14px nghiêng
    public static let quoteItalic: UIFont = {
        let base = lora(size: 14, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 14)
    }()

    /// Số đếm lớn trên màn immersive (vd. số hạt màn Niệm Phật) — thiết kế dùng weight 300 nhưng
    /// bộ font Be Vietnam Pro trong bundle chưa có bản Light nên dùng Regular.
    public static let immersiveCount = beVietnamPro(size: 58, weight: .regular)
    /// Dòng gợi ý thao tác dưới câu niệm: Lora 12.5px nghiêng
    public static let hintItalic: UIFont = {
        let base = lora(size: 12.5, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 12.5)
    }()

    /// Đoạn mô tả dài dưới tiêu đề intro (Onboarding)
    public static let introBody = beVietnamPro(size: 15, weight: .regular)
    /// Wordmark viết hoa, letter-spacing rộng ở top bar (Onboarding)
    public static let logoMark = beVietnamPro(size: 11.5, weight: .semibold)

    // MARK: - Alert / Error Popups
    /// Error bottom-sheet title and the large "!" glyph on sheet / dialog: Lora 24px
    public static let alertTitle = lora(size: 24, weight: .regular)
    /// Small "!" glyph on toast / banner: Lora 14px medium
    public static let alertGlyphSmall = lora(size: 14, weight: .medium)
    /// Toast / banner headline: 13.5px medium
    public static let alertHeadline = beVietnamPro(size: 13.5, weight: .medium)
    /// Close "×" on the toast: 15px
    public static let alertClose = beVietnamPro(size: 15, weight: .regular)
    /// Close "×" on the full-screen error: 17px
    public static let alertCloseLarge = beVietnamPro(size: 17, weight: .regular)
    /// Dialog pill buttons: 13px medium
    public static let alertDialogButton = beVietnamPro(size: 13, weight: .medium)
    /// Full-screen error pill buttons: 14px medium
    public static let alertFullButton = beVietnamPro(size: 14, weight: .medium)
    /// Full-screen error body — design uses weight 300, but the bundled Be Vietnam Pro set has no
    /// Light cut yet, so Regular is used (same trade-off as `immersiveCount`).
    public static let alertFullBody = beVietnamPro(size: 14.5, weight: .regular)
    
    // MARK: - Attributed Text Helpers
    
    /// Tạo NSAttributedString với letter spacing (kern) và line-height chuẩn
    public static func makeAttributedString(
        text: String,
        font: UIFont,
        color: UIColor,
        lineHeightMultiple: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        letterSpacingEm: CGFloat? = nil,
        alignment: NSTextAlignment = .left
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        if let lineHeightMultiple = lineHeightMultiple {
            paragraphStyle.lineHeightMultiple = lineHeightMultiple
        }
        if let lineSpacing = lineSpacing {
            paragraphStyle.lineSpacing = lineSpacing
        }
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        if let em = letterSpacingEm {
            attributes[.kern] = font.pointSize * em
        }
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// Paragraph matching a CSS `line-height` multiplier from the design handoff (e.g. `1.65`):
    /// the extra space over the font's natural line height becomes `lineSpacing`.
    public static func makeParagraph(
        text: String,
        font: UIFont,
        color: UIColor,
        cssLineHeight: CGFloat,
        alignment: NSTextAlignment = .left
    ) -> NSAttributedString {
        makeAttributedString(
            text: text,
            font: font,
            color: color,
            lineSpacing: max(0, font.pointSize * cssLineHeight - font.lineHeight),
            alignment: alignment
        )
    }

    /// Định dạng text Eyebrow viết hoa với letter spacing 0.14em
    public static func makeEyebrow(text: String, color: UIColor = ILColors.inkMuted) -> NSAttributedString {
        makeAttributedString(
            text: text.uppercased(),
            font: eyebrow,
            color: color,
            letterSpacingEm: 0.14
        )
    }
    
    /// Định dạng câu kinh văn với Lora và line-height thoáng (1.75)
    public static func makeScriptureText(
        text: String,
        size: CGFloat = 18,
        color: UIColor = ILColors.ink,
        alignment: NSTextAlignment = .center
    ) -> NSAttributedString {
        makeAttributedString(
            text: text,
            font: lora(size: size, weight: .regular),
            color: color,
            lineHeightMultiple: 1.75,
            alignment: alignment
        )
    }
}
