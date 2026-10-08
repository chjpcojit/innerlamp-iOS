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

    // MARK: - Bottom Nav (template, 28×28)
    /// Center lamp of `ILBottomNavBar` — solid (normal state)
    public static let tabLampFilled = template("tab_lamp_filled")

    /// Center lamp of `ILBottomNavBar` — stroked (highlighted state)
    public static let tabLampOutline = template("tab_lamp_outline")

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

    // MARK: - Illustrations (full-color)
    /// Lamp + glow, 114×160 — Onboarding intro, Login header
    public static let onboardingLamp = illustration("onboarding_lamp")

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
