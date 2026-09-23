//
//  ILColors.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

/// Mọi màu base lấy từ `Assets.xcassets/Colors` — file này chỉ load bằng tên
/// (`UIColor(named:)`), không hardcode hex ở đây. Đổi màu = sửa color asset,
/// không sửa Swift. Biến thể alpha (secondary/muted/tint...) derive từ màu
/// base bằng `withAlphaComponent`, không tạo asset riêng cho từng alpha.
public enum ILColors {

    /// Named color không tìm thấy trong `Colors.xcassets` — crash sớm lúc dev
    /// thay vì âm thầm render màu đen sai ở UI.
    private static func asset(_ name: String) -> UIColor {
        guard let color = UIColor(named: name, in: .main, compatibleWith: nil) else {
            fatalError("Missing color asset '\(name)' in Assets.xcassets/Colors — add it there, never hardcode hex.")
        }
        return color
    }

    // MARK: - Canvas & Backgrounds
    /// Nền mặc định các màn danh sách
    public static let canvas = asset("ILCanvas")

    /// Nền màn form / đọc kinh
    public static let canvasWarm = asset("ILCanvasWarm")

    /// Điểm kết thúc gradient nền ấm
    public static let canvasWarmEnd1 = asset("ILCanvasWarmEnd1")

    /// Điểm kết thúc gradient nền ấm biến thể
    public static let canvasWarmEnd2 = asset("ILCanvasWarmEnd2")

    // MARK: - Surfaces
    /// Thẻ, hàng danh sách, input
    public static let surface = asset("ILSurface")

    /// Thẻ trên nền tối
    public static let surfaceDark = asset("ILSurfaceDark")

    /// Thẻ tối nâng cao khi hover / active
    public static let surfaceDarkElevated = asset("ILSurfaceDarkElevated")

    /// Nền tối cho màn thiền / player
    public static let darkBackground = asset("ILDarkBackground")

    /// Nền gradient tối đỉnh
    public static let darkBackgroundTop = asset("ILDarkBackgroundTop")

    /// Track, cột biểu đồ, nền avatar chồng — 3 mức đậm dần (`--il-tint` → `--il-tint3`)
    public static let tint = asset("ILTint")
    public static let tint2 = asset("ILTint2")
    public static let tint3 = asset("ILTint3")

    // MARK: - Inks (Typography & Primary CTAs)
    /// Chữ chính, nút primary
    public static let ink = asset("ILInk")

    /// Chữ phụ trên nền sáng (alpha 0.70 của `ink`)
    public static let inkSecondary = ink.withAlphaComponent(0.70)

    /// Chữ thứ cấp trên nền sáng (alpha 0.50 của `ink`)
    public static let inkTertiary = ink.withAlphaComponent(0.50)

    /// Chữ mờ / placeholder / caption trên nền sáng (alpha 0.42 của `ink`)
    public static let inkMuted = ink.withAlphaComponent(0.42)

    /// Chữ vô hiệu hóa trên nền sáng (alpha 0.30 của `ink`)
    public static let inkDisabled = ink.withAlphaComponent(0.30)

    /// Chữ mô tả dài trên nền sáng (alpha 0.66 của `ink`)
    public static let inkDim = ink.withAlphaComponent(0.66)

    /// Chữ nút phụ / label phụ ít nổi bật (alpha 0.45 của `ink`)
    public static let inkSubtle = ink.withAlphaComponent(0.45)

    /// Chữ eyebrow / caption rất mờ trên nền sáng (alpha 0.35 của `ink`)
    public static let inkFaint = ink.withAlphaComponent(0.35)

    /// Biến thể ink dùng riêng cho vài text tone (ví dụ `Tone.ink.textColor`)
    public static let inkSoft = asset("ILInkSoft")

    /// Chữ chính trên nền tối
    public static let inkOnDark = asset("ILInkOnDark")

    /// Chữ chính biến thể trên nền tối
    public static let inkOnDarkVariant = asset("ILInkOnDarkVariant")

    /// Chữ phụ trên nền tối (alpha 0.60 của `inkOnDarkVariant`)
    public static let inkOnDarkSecondary = inkOnDarkVariant.withAlphaComponent(0.60)

    /// Chữ mờ trên nền tối (alpha 0.42 của `inkOnDarkVariant`)
    public static let inkOnDarkTertiary = inkOnDarkVariant.withAlphaComponent(0.42)

    /// Chữ rất mờ trên nền tối (alpha 0.35 của `inkOnDarkVariant`)
    public static let inkOnDarkMuted = inkOnDarkVariant.withAlphaComponent(0.35)

    /// Chữ vô hiệu hóa trên nền tối (alpha 0.28 của `inkOnDarkVariant`)
    public static let inkOnDarkDisabled = inkOnDarkVariant.withAlphaComponent(0.28)

    /// Slogan dưới wordmark màn Splash (alpha 0.55 của `inkOnDark`)
    public static let inkOnDarkTagline = inkOnDark.withAlphaComponent(0.55)

    // MARK: - Accent & State Colors
    /// Nhấn chính, tiến trình, focus ring
    public static let gold = asset("ILGold")

    /// Ánh đèn, chấm trạng thái, glow
    public static let goldBright = asset("ILGoldBright")

    /// Đầu sáng ngọn lửa / tia quét trên nền tối — vàng nhạt hơn `goldBright`
    public static let goldLight = asset("ILGoldLight")

    /// Đầu sáng ngọn lửa trên nền sáng — ấm hơn `goldLight` một nhịp
    public static let goldSoft = asset("ILGoldSoft")

    /// Hạt than hồng bay lên ở màn Splash — hổ phách trung tính giữa `goldLight` và `goldBright`
    public static let goldEmber = asset("ILGoldEmber")

    /// Vầng sáng lan tỏa quanh ngọn đèn (alpha 0.20 của `goldBright`)
    public static let goldGlow = goldBright.withAlphaComponent(0.20)

    /// Vầng sáng đậm của màn luôn tối (alpha 0.26 của `goldBright`)
    public static let goldGlowStrong = goldBright.withAlphaComponent(0.26)

    /// Nền radial bên trong vòng đèn trên nền tối (alpha 0.28 của `goldBright`)
    public static let goldRingFill = goldBright.withAlphaComponent(0.28)

    /// Nền radial bên trong vòng đèn trên nền sáng (alpha 0.24 của `goldBright`)
    public static let goldRingFillSoft = goldBright.withAlphaComponent(0.24)

    /// Điểm kết thúc trong suốt của vầng sáng (alpha 0 của `goldBright`)
    public static let goldGlowClear = goldBright.withAlphaComponent(0.0)

    /// Nền nhấn nhẹ cho ô ngày trai trong lịch tháng (alpha 0.14 của `gold`)
    public static let goldDayTint = gold.withAlphaComponent(0.14)

    /// Chữ phụ trên nền `ink` đảo (vd. số ngày âm trong ô đang chọn) — alpha 0.60 của `canvas`
    public static let canvasOnInkSecondary = canvas.withAlphaComponent(0.60)

    // MARK: - Bottom Nav Lamp
    /// Chân bấc ngọn đèn trên nút Đèn ở chế độ tối (nền `goldBright`) — cố định `#1A1611`,
    /// không đổi theo theme (theo `lampFlame` của `IL-BottomNav`).
    public static let lampFlameDark = asset("ILLampFlameDark")

    /// Viền vòng đèn (alpha 0.45 của `gold`)
    public static let goldBorder = gold.withAlphaComponent(0.45)

    /// Viền thẻ nhấn nhẹ trên nền sáng — nhạt hơn `goldBorder` (alpha 0.35 của `gold`)
    public static let goldCardBorder = gold.withAlphaComponent(0.35)

    /// Viền vòng đèn trên nền tối — rõ hơn `goldBorder` (alpha 0.50 của `gold`)
    public static let goldBorderOnDark = gold.withAlphaComponent(0.50)

    /// Vòng ripple lan ra của màn Splash — ba mức alpha theo thứ tự phát (0.50 → 0.30 của `goldBright`)
    public static let goldRippleStrong = goldBright.withAlphaComponent(0.50)
    public static let goldRippleSoft = goldBright.withAlphaComponent(0.40)
    public static let goldRippleFaint = goldBright.withAlphaComponent(0.30)

    /// Tia sáng quét hai bên vòng đèn màn Splash (alpha 0.50 → 0.35 của `goldLight`)
    public static let goldRayStrong = goldLight.withAlphaComponent(0.50)
    public static let goldRaySoft = goldLight.withAlphaComponent(0.35)

    /// Chữ nhấn trên nền sáng
    public static let goldDeep = asset("ILGoldDeep")

    /// Thiền, thành công
    public static let green = asset("ILGreen")

    /// Chữ thiền / thành công
    public static let greenText = asset("ILGreenText")

    /// Niệm Phật, cảnh báo mềm
    public static let rose = asset("ILRose")

    /// Chữ niệm Phật / cảnh báo mềm
    public static let roseText = asset("ILRoseText")

    /// Lỗi form, hành động xóa
    public static let danger = asset("ILDanger")

    /// Chữ nhấn / link — `goldDeep` ở light, `#E8B061` ở dark (`--il-link`)
    public static let link = asset("ILLink")

    // MARK: - Immersive screens (bộ `--il-med-*`: Phiên thiền, Hoàn thành, Niệm Phật, Sen Vàng)
    /// Tâm và mép của gradient nền radial — đổi theo light/dark
    public static let medBackgroundCenter = asset("ILMedBackgroundCenter")
    public static let medBackgroundEdge = asset("ILMedBackgroundEdge")

    /// Chữ chính và điểm nhấn vàng trên nền immersive — đổi theo light/dark
    public static let medInk = asset("ILMedInk")
    public static let medGold = asset("ILMedGold")

    /// Chữ phụ / gợi ý / chú thích trên nền immersive. Alpha khác nhau giữa light và dark nên
    /// nằm trong chính color set (`--il-med-38`, `--il-med-42`, `--il-med-3`).
    public static let medInkSecondary = asset("ILMedInkSecondary")
    public static let medInkTertiary = asset("ILMedInkTertiary")
    public static let medInkMuted = asset("ILMedInkMuted")

    /// Track thanh tiến trình và viền nút ghost trên nền immersive (`--il-med-12`, `--il-med-22`)
    public static let medTrack = medInk.withAlphaComponent(0.12)
    public static let medBorder = medInk.withAlphaComponent(0.22)

    /// Chỉ vạch giữa dây tràng hạt và vòng đánh dấu hạt hiện tại
    public static let medStrandLine = goldBright.withAlphaComponent(0.26)
    public static let medMarkerRing = goldBright.withAlphaComponent(0.28)
    public static let medMarkerRingActive = goldBright.withAlphaComponent(0.72)
    public static let medMarkerTick = goldBright.withAlphaComponent(0.30)

    /// Nút nhấn vàng nhạt trên nền immersive (nền + viền của nút "Xong")
    public static let medGoldTint = goldBright.withAlphaComponent(0.16)
    public static let medGoldTintBorder = goldBright.withAlphaComponent(0.40)

    // MARK: - Bead (không đổi theo theme)
    /// Hạt mẹ — gradient sáng → vàng → `goldDeep`
    public static let beadMotherLight = asset("ILBeadMotherLight")
    public static let beadMotherMid = asset("ILBeadMotherMid")
    public static let beadMotherBorder = beadMotherLight.withAlphaComponent(0.50)

    /// Hạt thường — gradient nâu sáng → nâu → nâu đậm
    public static let beadLight = asset("ILBeadLight")
    public static let beadMid = asset("ILBeadMid")
    public static let beadDark = asset("ILBeadDark")
    public static let beadBorder = goldBright.withAlphaComponent(0.16)

    /// Bóng đổ và lớp tối/sáng giả inset-shadow của hạt
    public static let beadShadow = UIColor.black.withAlphaComponent(0.60)
    public static let beadShade = UIColor.black.withAlphaComponent(0.50)
    public static let beadHighlight = beadMotherLight.withAlphaComponent(0.14)

    // MARK: - Borders
    /// Viền thẻ tiêu chuẩn (alpha 0.08 của `ink`)
    public static let border = ink.withAlphaComponent(0.08)

    /// Viền nút ghost, input active (alpha 0.18 của `ink`)
    public static let borderStrong = ink.withAlphaComponent(0.18)

    /// Viền thẻ trên nền tối (alpha 0.08 của `inkOnDarkVariant`)
    public static let borderDark = inkOnDarkVariant.withAlphaComponent(0.08)

    /// Viền nút / ô trên nền tối (alpha 0.16 của `inkOnDarkVariant`)
    public static let borderDarkStrong = inkOnDarkVariant.withAlphaComponent(0.16)

    // MARK: - Alert / Error Popups
    // Fixed palette (does not flip with theme) for the error popups — see
    // `Components/Alert/` and the "Popup lỗi" screen in the design handoff.

    /// Warm near-black (#241F19): snackbar background, label on light pill over dark backgrounds
    public static let nightInk = asset("ILNightInk")

    /// Deep warm black (#120E0A) used for modal scrims and popup shadows
    public static let scrim = asset("ILScrim")

    /// Dimming layer behind the error bottom sheet (alpha 0.46 of `scrim`)
    public static let scrimSheet = scrim.withAlphaComponent(0.46)

    /// Dimming layer behind the center error dialog (alpha 0.50 of `scrim`)
    public static let scrimDialog = scrim.withAlphaComponent(0.50)

    /// Rose glyph ("!") on dark backgrounds (full-screen error)
    public static let roseOnDark = asset("ILRoseOnDark")

    /// Dark rose background of the top action banner (#4A2F2C)
    public static let alertBanner = asset("ILAlertBanner")

    /// Primary text on the action banner + fill of its primary pill (#F7EFE6)
    public static let alertBannerInk = asset("ILAlertBannerInk")

    /// "!" glyph on the action banner (#F0C9C3)
    public static let alertBannerGlyph = asset("ILAlertBannerGlyph")

    /// Label color of the banner's primary pill (#3A2A26)
    public static let alertBannerButtonInk = asset("ILAlertBannerButtonInk")

    /// Alpha variants used only by the error popups, grouped to keep the flat list above readable.
    public enum Alert {
        // Light surfaces (toast, sheet, dialog) — derived from theme-aware bases, so they flip with dark mode.
        /// Toast border (alpha 0.50 of `rose`)
        public static let toastBorder = ILColors.rose.withAlphaComponent(0.50)
        /// Small "!" badge background on the toast (alpha 0.20 of `rose`)
        public static let glyphTintSmall = ILColors.rose.withAlphaComponent(0.20)
        /// Large "!" badge background on sheet / dialog / full screen (alpha 0.18 of `rose`)
        public static let glyphTint = ILColors.rose.withAlphaComponent(0.18)
        /// Outer ring of the full-screen error glyph (alpha 0.42 of `rose`)
        public static let glyphRing = ILColors.rose.withAlphaComponent(0.42)
        /// Close "×" on the toast (alpha 0.38 of `ink`)
        public static let closeGlyph = ILColors.ink.withAlphaComponent(0.38)
        /// Sheet grabber + dialog secondary pill border (alpha 0.14 of `ink`)
        public static let hairline = ILColors.ink.withAlphaComponent(0.14)
        /// Dialog secondary pill label (alpha 0.62 of `ink`)
        public static let secondaryLabel = ILColors.ink.withAlphaComponent(0.62)
        /// Shadow color of the light toast (`ink`, alpha applied by `ILMetrics.shadowToast`)
        public static let toastShadow = ILColors.ink

        // Action banner (always dark rose)
        /// "!" badge background on the banner (alpha 0.14 of white)
        public static let bannerGlyphTint = UIColor.white.withAlphaComponent(0.14)
        /// Banner message text (alpha 0.62 of `alertBannerInk`)
        public static let bannerMessage = ILColors.alertBannerInk.withAlphaComponent(0.62)
        /// Banner secondary pill border (alpha 0.28 of `alertBannerInk`)
        public static let bannerSecondaryBorder = ILColors.alertBannerInk.withAlphaComponent(0.28)
        /// Banner secondary pill label (alpha 0.80 of `alertBannerInk`)
        public static let bannerSecondaryLabel = ILColors.alertBannerInk.withAlphaComponent(0.80)

        // Full-screen error (always dark)
        /// Close button border + secondary button border (alpha 0.20 of `inkOnDark`)
        public static let fullBorder = ILColors.inkOnDark.withAlphaComponent(0.20)
        /// Close "×" glyph (alpha 0.60 of `inkOnDark`)
        public static let fullCloseGlyph = ILColors.inkOnDark.withAlphaComponent(0.60)
        /// Italic English subtitle (alpha 0.50 of `inkOnDark`)
        public static let fullSubtitle = ILColors.inkOnDark.withAlphaComponent(0.50)
        /// Body message (alpha 0.66 of `inkOnDark`)
        public static let fullMessage = ILColors.inkOnDark.withAlphaComponent(0.66)
        /// Error code + timestamp line (alpha 0.34 of `inkOnDark`)
        public static let fullFootnote = ILColors.inkOnDark.withAlphaComponent(0.34)
        /// Secondary button label (alpha 0.78 of `inkOnDark`)
        public static let fullSecondaryLabel = ILColors.inkOnDark.withAlphaComponent(0.78)
    }

    // MARK: - Semantic Helper
    public enum Tone {
        case gold
        case green
        case rose
        case ink

        public var accentColor: UIColor {
            switch self {
            case .gold: return ILColors.gold
            case .green: return ILColors.green
            case .rose: return ILColors.rose
            case .ink: return ILColors.goldDeep
            }
        }

        public var textColor: UIColor {
            switch self {
            case .gold: return ILColors.goldDeep
            case .green: return ILColors.greenText
            case .rose: return ILColors.roseText
            case .ink: return ILColors.inkSoft
            }
        }

        public var tintBackground: UIColor {
            switch self {
            case .gold: return ILColors.gold.withAlphaComponent(0.16)
            case .green: return ILColors.green.withAlphaComponent(0.18)
            case .rose: return ILColors.rose.withAlphaComponent(0.18)
            case .ink: return ILColors.goldDeep.withAlphaComponent(0.14)
            }
        }

        public var avatarBackground: UIColor {
            switch self {
            case .gold: return ILColors.gold.withAlphaComponent(0.18)
            case .green: return ILColors.green.withAlphaComponent(0.18)
            case .rose: return ILColors.rose.withAlphaComponent(0.20)
            case .ink: return ILColors.ink.withAlphaComponent(0.08)
            }
        }

        public var avatarBorder: UIColor {
            switch self {
            case .gold: return ILColors.gold.withAlphaComponent(0.32)
            case .green: return ILColors.green.withAlphaComponent(0.30)
            case .rose: return ILColors.rose.withAlphaComponent(0.32)
            case .ink: return ILColors.ink.withAlphaComponent(0.12)
            }
        }
    }
}

// MARK: - UIColor Hex Extension
// Legacy utility kept for existing call sites (ILButton, ILRow, ILField, ...) that still
// construct one-off colors inline. New code must NOT use this — pull from `ILColors` (or add a
// new asset + `ILColors` constant if the color doesn't exist yet), never `UIColor(hex:)` directly.
public extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        let r, g, b: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
        } else {
            r = 0
            g = 0
            b = 0
        }

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
