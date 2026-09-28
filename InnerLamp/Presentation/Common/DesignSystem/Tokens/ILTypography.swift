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
    /// Tiêu đề track trình phát toàn màn (vd. "Phẩm Song Yếu") — 25px Lora theo design handoff
    /// (màn `player`, `font:400 25px/1.3 Lora`).
    public static let playerTitle = lora(size: 25, weight: .regular)
    /// Tiêu đề Lora lớn trong hero tối của màn chi tiết nội dung (kinh / pháp thoại) — 29px theo
    /// design handoff (màn `detail`, dòng tiêu đề "Kinh Pháp Cú").
    public static let contentHeroTitle = lora(size: 29, weight: .regular)
    /// Tiêu đề Lora hero màn Pháp thoại — 27px theo design handoff (màn `talk`, dòng tiêu đề
    /// "Hiếu là đạo, đạo cũng là hiếu", `font:400 27px/1.32 Lora`). Khác `contentHeroTitle` (29px)
    /// một nhịp nên cần preset riêng.
    public static let talkTitle = lora(size: 27, weight: .regular)
    /// Số ngày âm lớn ở hero màn "Chi tiết ngày âm" — 72px Lora theo design handoff (`font:400 72px/0.9`).
    public static let lunarHeroDay = lora(size: 72, weight: .regular)
    public static let scriptureTitle = lora(size: 22, weight: .regular)
    public static let scriptureBodyLarge = lora(size: 20, weight: .regular)
    /// Kệ kinh chính trên màn Tụng kinh (`isReader`) — 21px Lora theo design handoff, luôn dùng cùng
    /// line-height 1.6 ở nơi gọi.
    public static let readerVerse = lora(size: 21, weight: .regular)
    /// Bản dịch Anh dưới kệ kinh trên màn Tụng kinh — 13.5px Lora nghiêng, luôn dùng cùng line-height
    /// 1.7 ở nơi gọi (xem `ILReaderVerseView`).
    public static let readerTranslation: UIFont = {
        let base = lora(size: 13.5, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 13.5)
    }()
    /// Tiêu đề thẻ tối nổi bật (vd. "Thời khóa tối cùng đạo tràng") — 19px Lora theo design handoff.
    public static let heroCardTitle = lora(size: 19, weight: .regular)
    public static let scriptureBody = lora(size: 18, weight: .regular)
    /// Số serif (Lora) 18px — vd. số phút trong vòng tròn preset thiền ở màn Thiền định.
    public static let serifNumber = lora(size: 18, weight: .regular)
    /// Số ngày trong ô ngày của thẻ sự kiện (17px Lora theo design handoff).
    public static let dateTileDay = lora(size: 17, weight: .regular)
    public static let scriptureBodySmall = lora(size: 15, weight: .regular)
    /// Đoạn mô tả ngắn dưới hero (vd. giới thiệu bộ kinh ở màn chi tiết bài kinh) — 14px Lora, luôn
    /// dùng cùng line-height ~1.75 ở nơi gọi.
    public static let scriptureDescription = lora(size: 14, weight: .regular)
    /// Tiêu đề ảnh trong gallery "Ảnh chùa đẹp" — 13.5px Lora theo design handoff.
    public static let photoCaptionTitle = lora(size: 13.5, weight: .regular)
    /// Nhãn ô truy cập nhanh màn Thư viện (Kinh sách/Thiền định/Pháp thoại/Phật & Bồ Tát) — 16px
    /// Lora theo design handoff (`isLib`, `font:400 16px Lora`).
    public static let quickAccessTileTitle = lora(size: 16, weight: .regular)
    /// Tiêu đề serif (Lora) 16px cho thẻ/hàng danh sách (vd. tên preset thiền chuông và tên bài
    /// thiền dẫn ở màn Thiền định) — `font:400 16px Lora` trong design handoff.
    public static let serifCardTitle = lora(size: 16, weight: .regular)
    /// Chữ "A" nhỏ ở đầu trái thanh chỉnh cỡ chữ kinh văn (màn Cài đặt) — 12px Lora theo design handoff.
    public static let scriptureBodyTiny = lora(size: 12, weight: .regular)
    /// Đoạn thân bài viết Phật pháp (màn Bài viết) — 16px Lora, luôn dùng cùng line-height 1.85
    /// ở nơi gọi (`makeParagraph(cssLineHeight: 1.85)`).
    public static let articleBody = lora(size: 16, weight: .regular)
    /// Thân bài đăng đạo tràng (màn Bài đăng) — 14.5px Lora theo design handoff (`font:400
    /// 14.5px/1.8 Lora`), luôn dùng cùng line-height 1.8 ở nơi gọi (`makeParagraph(cssLineHeight: 1.8)`).
    public static let postBody = lora(size: 14.5, weight: .regular)
    /// Câu trích dẫn nổi bật trong bài viết Phật pháp — 18px Lora nghiêng, luôn dùng cùng
    /// line-height 1.6 ở nơi gọi (xem `ILArticleQuoteView`).
    public static let articleQuote: UIFont = {
        let base = lora(size: 18, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 18)
    }()
    /// Danh xưng lớn trên hero ảnh (màn chi tiết Phật & Bồ Tát) — 28px Lora, line-height 1.2.
    public static let imageHeroTitle = lora(size: 28, weight: .regular)
    /// Dòng phụ nghiêng dưới tiêu đề hero / Phạn ngữ trên thẻ thần chú — 13px Lora nghiêng.
    public static let heroSubtitleItalic: UIFont = {
        let base = lora(size: 13, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 13)
    }()

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
    /// Eyebrow vàng nhỏ trên thẻ tối (vd. "SẮP DIỄN RA · 30 PHÚT NỮA") — 9.5px semibold theo design handoff.
    public static let eyebrowSmall = beVietnamPro(size: 9.5, weight: .semibold)
    public static let captionSmall = beVietnamPro(size: 9.5, weight: .medium)
    public static let caption = beVietnamPro(size: 10.5, weight: .regular)
    public static let label = beVietnamPro(size: 11, weight: .regular)
    /// Nhãn hành động nhỏ đậm (vd. "Tán thán N", "Trả lời" ở màn Bài đăng đạo tràng) — 11px medium
    /// theo design handoff (`font:500 11px`).
    public static let labelMedium = beVietnamPro(size: 11, weight: .medium)
    public static let subhead = beVietnamPro(size: 11.5, weight: .regular)
    public static let subheadMedium = beVietnamPro(size: 11.5, weight: .medium)
    public static let chip = beVietnamPro(size: 12, weight: .medium)
    public static let bodySmall = beVietnamPro(size: 12.5, weight: .regular)
    public static let bodySmallMedium = beVietnamPro(size: 12.5, weight: .medium)
    public static let sectionTitle = beVietnamPro(size: 13, weight: .medium)
    public static let body = beVietnamPro(size: 13.5, weight: .regular)
    /// Thân chữ đậm (vd. tên tác giả, tiêu đề "N lời chia sẻ" ở màn Bài đăng đạo tràng) — 13.5px
    /// medium theo design handoff (`font:500 13.5px`).
    public static let bodyMedium = beVietnamPro(size: 13.5, weight: .medium)
    public static let button = beVietnamPro(size: 13.5, weight: .medium)
    public static let headerTitle = beVietnamPro(size: 13.5, weight: .medium)
    public static let bodyLarge = beVietnamPro(size: 14, weight: .regular)
    public static let rowTitle = beVietnamPro(size: 14, weight: .medium)
    public static let title2 = beVietnamPro(size: 16, weight: .semibold)
    /// Nhãn nút chọn trong thanh option rộng đều (vd. "5", "12", "20" ở màn Chuẩn bị thiền) —
    /// 16px medium theo design handoff (`font:500 16px`).
    public static let optionChip = beVietnamPro(size: 16, weight: .medium)
    /// Ký tự Hán 喜/財 ở ô glyph "Hướng xuất hành" (màn Chi tiết ngày âm) — 20px; bộ font không có
    /// nét CJK nên tự fallback sang font hệ thống, size vẫn giữ đúng 20px.
    public static let directionGlyph = beVietnamPro(size: 20, weight: .medium)
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
    /// Số liệu cột trong dải 3 ô thống kê (vd. Trang chùa) — 19px medium theo design handoff.
    public static let statValueMedium = beVietnamPro(size: 19, weight: .medium)
    /// Hero stat number on a featured card — 46px regular (e.g. "42" streak days on Stats).
    public static let statHero = beVietnamPro(size: 46, weight: .regular)
    /// Số liệu lớn kiểu serif (Lora) trên thẻ nổi bật — 34px theo design handoff (vd. "7 ngày thiền
    /// liên tục" ở màn Thiền định).
    public static let statDisplay = lora(size: 34, weight: .regular)
    /// Value inside a half-width stat tile — 24px medium (e.g. "168" hours on Stats).
    public static let statTileValue = beVietnamPro(size: 24, weight: .medium)
    /// Chú thích rất nhỏ 10px regular (vd. dòng phụ dưới tên dấu ấn)
    public static let microCaption = beVietnamPro(size: 10, weight: .regular)
    /// Nhãn rất nhỏ 8.5px medium (vd. "PHÚT" dưới số phút ở vòng tròn preset thiền).
    public static let microLabel = beVietnamPro(size: 8.5, weight: .medium)
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
    /// Số đếm lớn trên pad màn Chuông mõ (54px, weight 300 trong thiết kế → Regular).
    public static let bellPadNumber = beVietnamPro(size: 54, weight: .regular)
    /// Countdown inside the breathing ring on the meditation session screen (54px, weight 300 in
    /// the design → Regular, since the bundled Be Vietnam Pro has no Light cut).
    public static let immersiveTimer = beVietnamPro(size: 54, weight: .regular)
    /// Giá trị nhịp/khoảng cách trên thẻ nhịp màn Chuông mõ (17px medium).
    public static let bellRateValue = beVietnamPro(size: 17, weight: .medium)
    /// Dòng gợi ý thao tác dưới câu niệm: Lora 12.5px nghiêng
    public static let hintItalic: UIFont = {
        let base = lora(size: 12.5, weight: .regular)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 12.5)
    }()

    /// Đoạn mô tả dài dưới tiêu đề intro (Onboarding)
    public static let introBody = beVietnamPro(size: 15, weight: .regular)

    /// Value text inside a labeled input card (Edit Profile fields, 15px)
    public static let fieldValue = beVietnamPro(size: 15, weight: .regular)
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
