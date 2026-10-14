//
//  ILIcons.swift
//  InnerLamp
//

import UIKit

/// Every raster icon comes from `Assets.xcassets/Icons` — this file only loads by name
/// (`UIImage(named:)`), screens never call `UIImage(named:)` themselves. Adding an icon =
/// add the `.imageset` (see `DESIGN_SYSTEM.md` §7) and one constant here.
///
/// Two kinds of icon, and the rendering mode is decided here, not at the call site:
/// - **Template** (monochrome): loaded with `.alwaysTemplate`, the caller tints via `tintColor`.
/// - **Illustration** (full-color): loaded with `.alwaysOriginal`, never tinted.
public enum ILIcons {

    /// Icon not found in `Assets.xcassets/Icons` — crash early during development
    /// instead of silently rendering an empty image in the UI.
    private static func asset(_ name: String, renderingMode: UIImage.RenderingMode) -> UIImage {
        guard let image = UIImage(named: name, in: .main, compatibleWith: nil) else {
            fatalError("Missing icon asset '\(name)' in Assets.xcassets/Icons — add it there, never load images by name in a screen.")
        }
        return image.withRenderingMode(renderingMode)
    }

    private static func template(_ name: String) -> UIImage {
        asset(name, renderingMode: .alwaysTemplate)
    }

    private static func illustration(_ name: String) -> UIImage {
        asset(name, renderingMode: .alwaysOriginal)
    }

    // MARK: - Bottom Nav (template, 44×44 vector — tinted by `ILBottomNavBar`)
    /// Pagoda — "Trang chủ" tab
    public static let tabHome = template("tab_home")

    /// Two splayed books — "Thư viện" tab
    public static let tabLib = template("tab_lib")

    /// Temple with arched door — "Chùa" tab
    public static let tabSangha = template("tab_sangha")

    /// Person bust — "Tôi" tab
    public static let tabMe = template("tab_me")

    /// Outer flame (40×56 viewBox) of the center lamp button
    public static let tabLampFlame = template("tab_lamp_flame")

    /// Inner core (40×56 viewBox, same frame as `tabLampFlame`) of the center lamp button — a
    /// separate layer so it can take a different tint than the outer flame
    public static let tabLampCore = template("tab_lamp_core")

    // MARK: - Glyphs (template, 12×12 vector — tint via `tintColor`)
    /// Down chevron of `ILMenuFieldView`
    public static let chevronDown = template("chevron_down")

    /// Check mark of `ILInlineBannerView`
    public static let checkmark = template("check")

    /// Three text lines (16×12.8) inside the "lecture not split into parts" empty block of the Talk screen
    public static let linesEmpty = template("lines_empty")

    /// Person bust (18×18) on the gold "me" zoom button of the family tree
    public static let personViewer = template("person_viewer")

    /// Headphones (22×22) — audio talk tile in the Talks list
    public static let talkAudio = template("talk_audio")

    /// Play-in-rounded-rect (22×22) — video talk tile in the Talks list
    public static let talkVideo = template("talk_video")

    /// Document with lines (22×22) — written-transcript talk tile in the Talks list
    public static let talkText = template("talk_text")

    // MARK: - Home section icons (template, 44×44 vector — drawn inside a tinted tile)
    /// Four-point sparkle — "Sự kiện Phật giáo" section header
    public static let homeEvent = template("home_event")

    /// Framed landscape photo — "Ảnh chùa đẹp" section header
    public static let homePhoto = template("home_photo")

    /// Pagoda — "Chùa Việt Nam" section header
    public static let homeTemple = template("home_temple")

    /// Seated Buddha with halo — "Thư viện Phật & Bồ Tát" section header
    public static let homeBuddha = template("home_buddha")

    /// Prayer beads — "Tràng hạt · Niệm Phật" section header
    public static let homeBeads = template("home_beads")

    /// Clock — "Thời khóa gợi ý" section header
    public static let homeSchedule = template("home_schedule")

    /// Document with lines — "Bài viết Phật pháp hay" section header
    public static let homeArticle = template("home_article")

    /// Wooden fish disc with slot — "Chuông mõ" card on the Home screen
    public static let homeMo = template("home_mo")

    // MARK: - List-row icons (template, 44×44 vector — fills the 44×44 tile of `ILRow`)
    /// Seated meditator — `ILRow.Glyph.leaf` (meditation sessions)
    public static let rowMed = template("row_med")

    /// Two tilted books — `ILRow.Glyph.book` (sutras)
    public static let rowBook = template("row_book")

    /// Oil lamp with flame — `ILRow.Glyph.circle` (lamp offering)
    public static let rowLamp = template("row_lamp")

    /// Four sound bars — `ILRow.Glyph.dot` (talks)
    public static let rowTalk = template("row_talk")

    // MARK: - Profile menu / donate icons (template, 44×44 vector — `IL-Icon` glyphs of the prototype)
    /// Person bust (head + shoulders) — "Sửa hồ sơ"
    public static let rowUser = template("row_user")

    /// Family tree (three nodes joined by a branch) — "Gia phả dòng họ"
    public static let rowTree = template("row_tree")

    /// Plus sign — "Tạo gia phả mới"
    public static let rowPlus = template("row_plus")

    /// Mindfulness bell — "Chuông tỉnh thức"
    public static let rowBell = template("row_bell")

    /// Bell with a badge dot — "Thông báo"
    public static let rowNotif = template("row_notif")

    /// Journal book with two text lines — "Sổ công đức"
    public static let rowJournal = template("row_journal")

    /// Gear with a centre hole — "Cài đặt"
    public static let rowGear = template("row_gear")

    /// Temple with a roof and a door — "Chùa tu tập"
    public static let rowTemple = template("row_temple")

    /// Lotus — "Ủng hộ InnerLamp" card
    public static let rowLotus = template("row_lotus")

    /// Calendar page with a date dot — "Hộ trì hằng tháng" card in the merit book
    public static let rowCalendar = template("row_calendar")

    // MARK: - Illustrations (full-color)
    /// Singing bowl photo, 200×200 — stage of the Chuông mõ screen (bell mode)
    public static let bellChuong = illustration("bell_chuong")

    /// Carved wooden fish photo, 200×200 — stage of the Chuông mõ screen (mõ modes)
    public static let bellMo = illustration("bell_mo")

    /// Wooden fish mallet (stick + round head), 34×126 — pivots around the bottom of the stick
    public static let bellMalletMo = illustration("bell_mallet_mo")

    /// Bell striker (stick + red padded head), 34×126 — pivots around the bottom of the stick
    public static let bellMalletBell = illustration("bell_mallet_bell")

    // MARK: - Photo viewer (template, 24×24 vector — tint via `tintColor`)
    /// Close (×) of the photo viewer top bar
    public static let viewerClose = template("viewer_close")

    /// Favorite heart, outline — photo not favorited
    public static let viewerHeart = template("viewer_heart")

    /// Favorite heart, solid — photo favorited
    public static let viewerHeartFilled = template("viewer_heart_filled")

    /// Previous-photo chevron of the photo viewer
    public static let viewerChevronLeft = template("viewer_chevron_left")

    /// Next-photo chevron of the photo viewer
    public static let viewerChevronRight = template("viewer_chevron_right")
}
