//
//  ILTypography.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit
import CoreText

public enum ILTypography {
    
    // MARK: - Font Family Names
    public static let cormorantMediumName = "CormorantGaramond-Medium"
    public static let cormorantMediumItalicName = "CormorantGaramond-MediumItalic"
    public static let cormorantSemiBoldName = "CormorantGaramond-SemiBold"
    public static let cormorantBoldName = "CormorantGaramond-Bold"

    public static let literataRegularName = "Literata-Regular"
    public static let literataItalicName = "Literata-Italic"

    public static let beVietnamProRegularName = "BeVietnamPro-Regular"
    public static let beVietnamProMediumName = "BeVietnamPro-Medium"
    public static let beVietnamProSemiBoldName = "BeVietnamPro-SemiBold"
    public static let beVietnamProBoldName = "BeVietnamPro-Bold"

    // MARK: - Font Resolvers with Fallback

    /// Cormorant Garamond (Serif) — display font: tiêu đề màn, tiêu đề thẻ/hàng, số lớn
    /// (`font:500 … 'Cormorant Garamond'` của design). Regular và medium đều dùng weight 500 của design.
    public static func cormorant(size: CGFloat, weight: UIFont.Weight = .regular, italic: Bool = false) -> UIFont {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = cormorantBoldName
        case .semibold:
            fontName = cormorantSemiBoldName
        default:
            fontName = italic ? cormorantMediumItalicName : cormorantMediumName
        }
        if let customFont = UIFont(name: fontName, size: size) {
            return withLiningNumerals(customFont)
        }
        // Fallback to the system serif font if the font file is missing from the bundle.
        let base = UIFont.systemFont(ofSize: size, weight: weight == .regular ? .medium : weight)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }

    /// Cormorant Garamond defaults to old-style figures, where "1" is drawn like a small-cap "I"
    /// (lunar day "1", "11"…). The design turns on `lnum` everywhere (`font-variant-numeric:
    /// lining-nums` / "Luôn bật chữ số thẳng hàng (lnum)" in the Design System), so every Cormorant
    /// font is created with Number Case = Upper Case Numbers, which CoreText maps to `lnum`.
    private static func withLiningNumerals(_ font: UIFont) -> UIFont {
        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kNumberCaseType,
                UIFontDescriptor.FeatureKey.selector: kUpperCaseNumbersSelector
            ]]
        ])
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    /// Literata (Serif) — chữ đọc: thân kinh văn, bài viết, bài đăng, dòng phụ nghiêng
    /// (`font:400 16px/1.8 Literata`, `italic 400 13px/1.5 Literata` của design).
    public static func literata(size: CGFloat, italic: Bool = false) -> UIFont {
        if let customFont = UIFont(name: italic ? literataItalicName : literataRegularName, size: size) {
            return customFont
        }
        let base = UIFont.systemFont(ofSize: size, weight: .regular)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        return UIFont(descriptor: italic ? (descriptor.withSymbolicTraits(.traitItalic) ?? descriptor) : descriptor, size: size)
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
    
    // Display (Cormorant Garamond 500) & reading text (Literata) — sizes follow the design scale:
    // display 18 / 22 / 28 / 32, reading 16 (body) / 13 (italic secondary).
    public static let displayLarge = cormorant(size: 32)
    public static let displayMedium = cormorant(size: 28)
    /// Tiêu đề track trình phát toàn màn (vd. "Phẩm Song Yếu") — 25px Cormorant Garamond theo design handoff
    /// (màn `player`, `font:400 25px/1.3 Cormorant Garamond`).
    public static let playerTitle = cormorant(size: 28)
    /// Tiêu đề Cormorant Garamond lớn trong hero tối của màn chi tiết nội dung (kinh / pháp thoại) — 29px theo
    /// design handoff (màn `detail`, dòng tiêu đề "Kinh Pháp Cú").
    public static let contentHeroTitle = cormorant(size: 28)
    /// Tiêu đề Cormorant Garamond hero màn Pháp thoại — 27px theo design handoff (màn `talk`, dòng tiêu đề
    /// "Hiếu là đạo, đạo cũng là hiếu", `font:400 27px/1.32 Cormorant Garamond`). Khác `contentHeroTitle` (29px)
    /// một nhịp nên cần preset riêng.
    public static let talkTitle = cormorant(size: 28)
    /// Số ngày âm lớn ở hero màn "Chi tiết ngày âm" — 72px Cormorant Garamond theo design handoff (`font:400 72px/0.9`).
    public static let lunarHeroDay = cormorant(size: 84)
    public static let scriptureTitle = cormorant(size: 22)
    public static let scriptureBodyLarge = literata(size: 16)
    /// Four user-selectable sizes (17 / 20 / 23 / 26px Literata) of a chanted line on the Reader screen
    /// (`isReader`, "Cỡ chữ" panel); always used with line-height 1.55 at the call site.
    public static let readerLineFonts: [UIFont] = [17, 20, 23, 26].map { literata(size: $0) }
    /// Preview sentence on the Language screen for the 4 sutra font-size presets (14 / 16 / 19 / 22px Literata).
    public static let languagePreviewFonts: [UIFont] = [14, 16, 19, 22].map { literata(size: $0) }
    /// English gloss under a chanted line on the Reader screen — 12.5px Literata italic, line-height 1.6.
    public static let readerGloss = literata(size: 13, italic: true)
    /// Bell / wooden-fish cue glyph (◉ •) in front of a chanted line — 11px semibold.
    public static let readerCue = beVietnamPro(size: 11, weight: .semibold)
    /// "A" tile of the Reader font-size picker — 13px Literata (`font:400 13px Literata`).
    public static let readerOptionSize = literata(size: 13)
    /// Tiêu đề thẻ tối nổi bật (vd. "Thời khóa tối cùng đạo tràng") — 19px Cormorant Garamond theo design handoff.
    public static let heroCardTitle = cormorant(size: 22)
    public static let scriptureBody = literata(size: 16)
    /// Số serif (Cormorant Garamond) 18px — vd. số phút trong vòng tròn preset thiền ở màn Thiền định.
    public static let serifNumber = cormorant(size: 22)
    /// Số ngày trong ô ngày của thẻ sự kiện (17px Cormorant Garamond theo design handoff).
    public static let dateTileDay = cormorant(size: 18)
    public static let scriptureBodySmall = literata(size: 16)
    /// Đoạn mô tả ngắn dưới hero (vd. giới thiệu bộ kinh ở màn chi tiết bài kinh) — 14px Literata, luôn
    /// dùng cùng line-height ~1.75 ở nơi gọi.
    public static let scriptureDescription = literata(size: 14)
    /// Tiêu đề ảnh trong gallery "Ảnh chùa đẹp" — 13.5px Cormorant Garamond theo design handoff.
    public static let photoCaptionTitle = cormorant(size: 18)
    /// Nhãn ô truy cập nhanh màn Thư viện (Kinh sách/Thiền định/Pháp thoại/Phật & Bồ Tát) — 16px
    /// Cormorant Garamond theo design handoff (`isLib`, `font:400 16px Cormorant Garamond`).
    public static let quickAccessTileTitle = cormorant(size: 18)
    /// Tiêu đề serif (Cormorant Garamond) 16px cho thẻ/hàng danh sách (vd. tên preset thiền chuông và tên bài
    /// thiền dẫn ở màn Thiền định) — `font:400 16px Cormorant Garamond` trong design handoff.
    public static let serifCardTitle = cormorant(size: 18)
    /// Chữ "A" nhỏ ở đầu trái thanh chỉnh cỡ chữ kinh văn (màn Cài đặt) — 12px Literata theo design handoff.
    public static let scriptureBodyTiny = literata(size: 12)
    /// Đoạn thân bài viết Phật pháp (màn Bài viết) — 16px Literata, luôn dùng cùng line-height 1.85
    /// ở nơi gọi (`makeParagraph(cssLineHeight: 1.85)`).
    public static let articleBody = literata(size: 16)
    /// Thân bài đăng đạo tràng (màn Bài đăng) — 14.5px Literata theo design handoff (`font:400
    /// 14.5px/1.8 Literata`), luôn dùng cùng line-height 1.8 ở nơi gọi (`makeParagraph(cssLineHeight: 1.8)`).
    public static let postBody = literata(size: 16)
    /// Câu trích dẫn nổi bật trong bài viết Phật pháp — 18px Cormorant Garamond nghiêng, luôn dùng cùng
    /// line-height 1.6 ở nơi gọi (xem `ILArticleQuoteView`).
    public static let articleQuote = cormorant(size: 20, italic: true)
    /// Danh xưng lớn trên hero ảnh (màn chi tiết Phật & Bồ Tát) — 28px Cormorant Garamond, line-height 1.2.
    public static let imageHeroTitle = cormorant(size: 28)
    /// Dòng phụ nghiêng dưới tiêu đề hero / Phạn ngữ trên thẻ thần chú — 13px Literata nghiêng.
    public static let heroSubtitleItalic = literata(size: 13, italic: true)

    // Family tree (Gia phả) — Cormorant Garamond, as in the design
    /// Name under a node on the tree canvas — 13.5px bold serif.
    public static let treeNodeName = cormorant(size: 13.5, weight: .bold)
    /// "ĐỜI 5" caption under a node name — 9px medium, kern .08em applied at the call site.
    public static let treeNodeMeta = beVietnamPro(size: 9, weight: .medium)
    /// Selected person's name in the detail sheet header — 22px bold serif.
    public static let treeSheetName = cormorant(size: 22, weight: .bold)
    /// Relation / lineage row name in the detail sheet — 16px semibold serif.
    public static let treeRelationName = cormorant(size: 16, weight: .semibold)
    /// Lineage chain row name — 15px semibold serif.
    public static let treeChainName = cormorant(size: 15, weight: .semibold)
    /// Italic biography note — 16px medium serif italic.
    public static let treeNote: UIFont = {
        let base = cormorant(size: 16, weight: .medium)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(.traitItalic) else { return base }
        return UIFont(descriptor: descriptor, size: 16)
    }()
    /// Clan name in the tree header — 25px semibold serif.
    public static let treeHeaderTitle = cormorant(size: 25, weight: .semibold)
    /// 譜 glyph on the tree header seal — 19px bold serif.
    public static let treeHeaderSeal = cormorant(size: 19, weight: .bold)
    /// Generation chip — 12px medium.
    public static let treeChip = beVietnamPro(size: 12, weight: .medium)
    /// "DỨT NHÁNH" marker under a node — 8.5px semibold, kern .14em applied at the call site.
    public static let treeBranchEnd = beVietnamPro(size: 8.5, weight: .semibold)
    /// "BẠN" pill on the viewer's node — 9.5px bold, kern .12em applied at the call site.
    public static let treeMePill = beVietnamPro(size: 9.5, weight: .bold)
    /// "BẠN" badge in the legend — 7px bold, kern .08em applied at the call site.
    public static let treeMeLegend = beVietnamPro(size: 7, weight: .bold)
    /// 忌 glyph and title of the TƯỞNG NIỆM card — 18px bold serif.
    public static let treeMemorialTitle = cormorant(size: 18, weight: .bold)
    /// Tile title in the TƯỞNG NIỆM card ("Thắp đèn") — 12.5px semibold.
    public static let treeTileTitle = beVietnamPro(size: 12.5, weight: .semibold)
    /// 譜 seal on the "Cây gia phả" empty-state / legend — 12px bold serif.
    public static let treeSealSmall = cormorant(size: 12, weight: .bold)
    /// 譜 seal on the "Lấy từ gia phả" card of the empty memorial book — 17px semibold serif.
    public static let treeSealMedium = cormorant(size: 17, weight: .semibold)
    /// Book name in the switcher menu — 18px semibold serif.
    public static let treeSwitcherTitle = cormorant(size: 18, weight: .semibold)
    /// Title of a tab/screen empty state with an illustration — 24px serif.
    public static let emptyStateTitle = cormorant(size: 28)
    /// Title of the empty family tree ("Chưa có gia phả") — 28px bold serif.
    public static let treeEmptyTitle = cormorant(size: 28, weight: .bold)
    /// Header card title of the "Tạo gia phả" form — 26px semi-bold serif.
    public static let treeCreateTitle = cormorant(size: 26, weight: .semibold)

    // Splash / Onboarding intro (Cormorant Garamond Serif)
    public static let introDisplay = cormorant(size: 32)
    public static let stepTitle = cormorant(size: 32)
    /// Tiêu đề màn xác thực (Đăng ký, OTP, Đăng nhập...) — 29px Cormorant Garamond theo design handoff.
    public static let authTitle = cormorant(size: 28)
    /// Dòng phụ đề chữ nghiêng dưới wordmark/tiêu đề — luôn dùng cùng `.italic()` ở nơi gọi.
    public static let taglineItalic = literata(size: 13, italic: true)
    /// Wordmark "InnerLamp" màn Splash — 32px Cormorant Garamond 500 theo design handoff.
    public static let splashWordmark = cormorant(size: 32)
    /// Slogan nghiêng dưới wordmark màn Splash — 20px Cormorant Garamond 500 italic.
    public static let splashTagline = cormorant(size: 20, italic: true)
    /// Tiêu đề màn Đăng nhập — 32px Cormorant Garamond 500 (`isLogin`, "Kính chào bạn").
    public static let loginTitle = cormorant(size: 32)
    /// Tiêu đề màn Đăng ký — 28px Cormorant Garamond 500 (`isSignup`, "Kết duyên cùng InnerLamp").
    public static let signUpTitle = cormorant(size: 28)
    
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
    /// 12.5px semibold — highlighted value such as "Với bạn" in the family-tree sheet
    public static let bodySmallSemibold = beVietnamPro(size: 12.5, weight: .semibold)
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
    /// Tên chùa tu tập trên thẻ tab Chùa — 20px Cormorant Garamond (`font:400 20px/1.3 Cormorant Garamond`).
    public static let templeCardTitle = cormorant(size: 22)
    /// Số ngày ở cột ngày-tháng của hàng khóa tu / ngày lễ — 18px medium (`font:500 18px`).
    public static let dateNumber = beVietnamPro(size: 18, weight: .medium)
    /// Số thống kê vừa 22px medium (vd. "168 giờ tu tập" ở thẻ 3 ô số liệu)
    public static let statValue = beVietnamPro(size: 22, weight: .medium)
    /// Số liệu cột trong dải 3 ô thống kê (vd. Trang chùa) — 19px medium theo design handoff.
    public static let statValueMedium = beVietnamPro(size: 19, weight: .medium)
    /// Hero stat number on a featured card — 46px regular (e.g. "42" streak days on Stats).
    public static let statHero = beVietnamPro(size: 46, weight: .regular)
    /// Số liệu lớn kiểu serif (Cormorant Garamond) trên thẻ nổi bật — 34px theo design handoff (vd. "7 ngày thiền
    /// liên tục" ở màn Thiền định).
    public static let statDisplay = cormorant(size: 32)
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
    /// Câu chia sẻ ngắn dạng trích dẫn: Literata 14px nghiêng
    public static let quoteItalic = literata(size: 13, italic: true)

    /// Số hạt trong vòng tràng hạt nhỏ của thẻ tràng hạt ở Trang chủ — 24px medium
    public static let malaCardCount = beVietnamPro(size: 24, weight: .medium)

    /// Số đếm lớn trên màn immersive (vd. số hạt màn Niệm Phật) — thiết kế dùng weight 300 nhưng
    /// bộ font Be Vietnam Pro trong bundle chưa có bản Light nên dùng Regular.
    public static let immersiveCount = beVietnamPro(size: 58, weight: .regular)
    /// Số đếm dưới sân khấu chuông/mõ màn Chuông mõ (34px, weight 300 trong thiết kế → Regular).
    public static let bellPadNumber = beVietnamPro(size: 34, weight: .regular)
    /// Countdown inside the breathing ring on the meditation session screen (54px, weight 300 in
    /// the design → Regular, since the bundled Be Vietnam Pro has no Light cut).
    public static let immersiveTimer = beVietnamPro(size: 54, weight: .regular)
    /// Giá trị nhịp/khoảng cách trên thẻ nhịp màn Chuông mõ (17px medium).
    public static let bellRateValue = beVietnamPro(size: 17, weight: .medium)
    /// Dòng gợi ý thao tác dưới câu niệm: Literata 12.5px nghiêng
    public static let hintItalic = literata(size: 13, italic: true)

    /// Đoạn mô tả dài dưới tiêu đề intro (Onboarding)
    public static let introBody = beVietnamPro(size: 15, weight: .regular)

    /// Value text inside a labeled input card (Edit Profile fields, 15px)
    public static let fieldValue = beVietnamPro(size: 15, weight: .regular)
    /// Wordmark viết hoa, letter-spacing rộng ở top bar (Onboarding)
    public static let logoMark = beVietnamPro(size: 13, weight: .semibold)

    // MARK: - Alert / Error Popups
    /// Error bottom-sheet title and the large "!" glyph on sheet / dialog: Cormorant Garamond 24px
    public static let alertTitle = cormorant(size: 28)
    /// Small "!" glyph on toast / banner: Cormorant Garamond 14px medium
    public static let alertGlyphSmall = cormorant(size: 18, weight: .medium)
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
    
    /// Định dạng câu kinh văn với Literata và line-height thoáng (1.75)
    public static func makeScriptureText(
        text: String,
        size: CGFloat = 18,
        color: UIColor = ILColors.ink,
        alignment: NSTextAlignment = .center
    ) -> NSAttributedString {
        makeAttributedString(
            text: text,
            font: literata(size: size),
            color: color,
            lineHeightMultiple: 1.75,
            alignment: alignment
        )
    }
}
