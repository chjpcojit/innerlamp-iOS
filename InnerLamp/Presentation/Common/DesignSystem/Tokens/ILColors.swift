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

    /// Đáy nền gradient ấm thứ hai (`--il-sunk2`) — kem đất `#EFE6D5` ở light, nâu đêm `#1B1712` ở
    /// dark. Dùng cho đỉnh hero "Chi tiết ngày âm".
    public static let sunk2 = asset("ILSunk2")

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

    /// Chữ thân bài đậm hơn `inkSecondary` một nhịp (alpha 0.80 của `ink`) — vd. đoạn thân bài
    /// viết Phật pháp (`--il-ink-8` trong design handoff).
    public static let inkStrong = ink.withAlphaComponent(0.80)

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

    // MARK: - Notifications hero card (luôn tối)
    /// Eyebrow vàng trên thẻ tối (alpha 0.90 của `goldBright`) — "SẮP DIỄN RA · 30 PHÚT NỮA".
    public static let goldOnDarkStrong = goldBright.withAlphaComponent(0.90)

    /// Nhãn nút ghost trên thẻ tối (alpha 0.80 của `inkOnDark`) — "Bỏ qua tối nay".
    public static let inkOnDarkStrong = inkOnDark.withAlphaComponent(0.80)

    /// Viền nút ghost trên thẻ tối (alpha 0.25 của `inkOnDark`).
    public static let inkOnDarkBorderSoft = inkOnDark.withAlphaComponent(0.25)

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
    /// Faint gold wash behind informational callouts (alpha 0.10 of `gold` — `rgba(184,134,47,.1)` in
    /// the design handoff, e.g. the giỗ date preview).
    public static let goldCallout = gold.withAlphaComponent(0.10)

    /// Track of a segmented toggle (alpha 0.06 of `ink` — `--il-ink-06`); the selected segment sits
    /// on it as a `surface` pill.
    public static let segmentedTrack = ink.withAlphaComponent(0.06)

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

    // MARK: - Mala counter card (Trang chủ)
    /// Hạt đã niệm trên vòng tràng hạt nhỏ — `#D9963C` (`goldBright`)
    public static let malaBeadLit = goldBright

    /// Viền ngoài 1px của hạt đã niệm (alpha 0.25 của `gold`)
    public static let malaBeadLitRing = gold.withAlphaComponent(0.25)

    /// Hạt chưa niệm trên vòng tràng hạt nhỏ (alpha 0.12 của `ink`)
    public static let malaBeadIdle = ink.withAlphaComponent(0.12)

    // MARK: - Bottom Nav Lamp
    /// Đầu sáng của gradient nền nút Đèn ở chế độ sáng (160°, `lampFlameLight` → `gold`) — cố định
    /// `#E6A94E` (theo `lampBg` của `IL-BottomNav`).
    public static let lampFlameLight = asset("ILLampFlameLight")

    /// Ngọn lửa ngoài trên nút Đèn ở chế độ sáng (nền gradient vàng) — cố định `#FFF8EC`
    /// (theo `lampFlame` của `IL-BottomNav`).
    public static let lampGlyphLight = asset("ILLampGlyphLight")

    /// Chân bấc ngọn đèn trên nút Đèn ở chế độ tối (nền `goldBright`) — cố định `#1A1611`,
    /// không đổi theo theme (theo `lampFlame` của `IL-BottomNav`).
    public static let lampFlameDark = asset("ILLampFlameDark")

    /// Chữ trên nút nền `goldBright` (vd. "Trì niệm với tràng hạt") — cố định `#1A1611` ở cả hai
    /// theme, dùng chung asset với `lampFlameDark`.
    public static let inkOnGold = lampFlameDark

    /// Viền vòng đèn (alpha 0.45 của `gold`)
    public static let goldBorder = gold.withAlphaComponent(0.45)

    /// Viền thẻ nhấn nhẹ trên nền sáng — nhạt hơn `goldBorder` (alpha 0.35 của `gold`)
    public static let goldCardBorder = gold.withAlphaComponent(0.35)

    /// Viền vòng ngoài artwork trình phát toàn màn (alpha 0.40 của `gold`).
    public static let goldRingBorder = gold.withAlphaComponent(0.40)

    /// Viền vòng trong artwork trình phát toàn màn (alpha 0.28 của `gold`).
    public static let goldRingInnerBorder = gold.withAlphaComponent(0.28)

    /// Viền vòng đèn trên nền tối — rõ hơn `goldBorder` (alpha 0.50 của `gold`)
    public static let goldBorderOnDark = gold.withAlphaComponent(0.50)

    /// Chữ nhấn trên nền sáng
    public static let goldDeep = asset("ILGoldDeep")

    /// Chữ vàng nhấn trên nền tối (`#E8B061` trong bảng vàng cố định của design handoff, "không
    /// đổi theo theme") — dùng cho các màn hero luôn tối (vd. chip "Tụng hằng ngày" ở màn chi tiết
    /// bài kinh), không phải `link` (token đổi theo light/dark).
    public static let goldOnDark = asset("ILGoldOnDark")

    // MARK: - Featured Card (theme-aware — `--il-feat-*` / `--il-hero-acc` in the handoff)
    /// Featured card gradient start (light `#F3E8D4` / dark `#2A2620`)
    public static let featBackgroundStart = asset("ILFeatBackgroundStart")
    /// Featured card gradient end (light `#E6D5B7` / dark `#181510`)
    public static let featBackgroundEnd = asset("ILFeatBackgroundEnd")
    /// Featured card border (light `rgba(138,90,24,.16)` / dark transparent)
    public static let featBorder = asset("ILFeatBorder")
    /// Radial glow in the featured card corner (light `rgba(196,146,60,.3)` / dark `rgba(217,150,60,.28)`)
    public static let featGlow = asset("ILFeatGlow")
    /// Transparent end of `featGlow` for the radial gradient
    public static let featGlowClear = featGlow.withAlphaComponent(0.0)
    /// Unfilled progress track on the featured card (light `rgba(138,90,24,.16)` / dark `rgba(245,238,224,.14)`)
    public static let featTrack = asset("ILFeatTrack")
    /// Eyebrow accent on the featured card (light `#74500F` / dark `rgba(217,150,60,.95)`)
    public static let featAccent = asset("ILFeatAccent")
    /// Secondary text on the featured card (alpha 0.60 of `ink` — `--il-th-sub`)
    public static let featSub = ink.withAlphaComponent(0.60)

    // MARK: - Lunar hero (Trang chủ — bộ `--il-hero-*` light/dark của design handoff)
    /// Chữ chính hero âm lịch Trang chủ (`--il-hero-ink`): `#221E19` ở light, `#F7F1E4` ở dark.
    public static let heroInk = asset("ILHeroInk")

    /// Chữ tháng âm hero âm lịch (`--il-hero-ink2`): `#4A4034` ở light, `#E9DFCC` ở dark.
    public static let heroInk2 = asset("ILHeroInk2")

    /// Chữ phụ hero âm lịch (`--il-hero-sub`) — 62% của `heroInk` (năm can chi + nguồn câu kinh).
    public static let heroSub = heroInk.withAlphaComponent(0.62)

    /// Eyebrow + chấm tròn hero âm lịch (`--il-hero-acc`) — dùng chung `featAccent`
    /// (`#74500F` light / `rgba(217,150,60,.95)` dark), giá trị trùng 1–1 trong design handoff.
    public static let heroAccent = featAccent

    /// Viền chấm tròn hero âm lịch (`--il-hero-acc2`) — 50% của `heroAccent` (khớp bản light;
    /// bản dark xấp xỉ 0.48, chênh không đáng kể, cùng cách `ILLunarDayDetailHeroView`).
    public static let heroAccentBorder = featAccent.withAlphaComponent(0.5)

    /// Ba điểm dừng overlay gradient hero âm lịch (`--il-hero-ov`) — wash đổi theo light/dark để
    /// chữ luôn đủ tương phản trên nền ảnh tượng Phật (hiện là gradient placeholder).
    public static let heroOverlayStart = asset("ILHeroOverlayStart")
    public static let heroOverlayMid = asset("ILHeroOverlayMid")
    public static let heroOverlayEnd = asset("ILHeroOverlayEnd")

    /// Thiền, thành công
    public static let green = asset("ILGreen")

    /// Chữ thiền / thành công
    public static let greenText = asset("ILGreenText")

    /// Viền trạng thái "đã tải về" (alpha 0.40 của `green`) — `rgba(110,143,122,.4)` trong design
    /// handoff (pill "Đã tải về" ở màn Thiền định).
    public static let greenBorder = green.withAlphaComponent(0.40)

    /// Nền nhạt trạng thái "đã tải về" (alpha 0.12 của `green`) — `rgba(110,143,122,.12)` trong
    /// design handoff (pill "Đã tải về" ở màn Thiền định).
    public static let greenTint = green.withAlphaComponent(0.12)

    /// Niệm Phật, cảnh báo mềm
    public static let rose = asset("ILRose")

    /// Chữ niệm Phật / cảnh báo mềm
    public static let roseText = asset("ILRoseText")

    /// Lỗi form, hành động xóa
    public static let danger = asset("ILDanger")
    /// Border of destructive action cards ("Xóa tài khoản", alpha 0.28 of `danger`)
    public static let dangerBorder = danger.withAlphaComponent(0.28)

    /// Chấm "Hoàng đạo" (ngày tốt) trong lịch tuần Trang chủ + nhãn chú thích — `#5E8A6C`,
    /// cố định không đổi theo theme (khớp `#5E8A6C` trong design handoff).
    public static let auspicious = asset("ILAuspicious")

    /// Biến thể sáng của `auspicious` dùng khi ô ngày đang chọn (nền mực tối) — `#8FC19E`.
    public static let auspiciousOnDark = asset("ILAuspiciousOnDark")

    /// Chấm "Hắc đạo" (ngày xấu) trong lịch tuần Trang chủ + nhãn chú thích — `#C64545`,
    /// cố định không đổi theo theme (khớp `#C64545` trong design handoff).
    public static let inauspicious = asset("ILInauspicious")

    /// Biến thể sáng của `inauspicious` dùng khi ô ngày đang chọn (nền mực tối) — `#E88A80`.
    public static let inauspiciousOnDark = asset("ILInauspiciousOnDark")

    /// Chữ "Tuổi xung khắc" ở màn Chi tiết ngày âm (`--il-clash-fg`) — đỏ đậm `#A23A3A` ở light,
    /// đỏ hồng nhạt `#E89A8E` ở dark (theme-aware, không phải đỏ cố định `inauspicious`).
    public static let clashForeground = asset("ILClashForeground")

    /// Nền chip "tuổi xung khắc" — alpha 0.10 của `clashForeground` (xấp xỉ `--il-clash-bg`).
    public static let clashTintBackground = clashForeground.withAlphaComponent(0.10)

    /// Viền chip "tuổi xung khắc" — alpha 0.24 của `clashForeground` (xấp xỉ `--il-clash-bd`).
    public static let clashBorder = clashForeground.withAlphaComponent(0.24)

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

    /// Vòng đánh dấu hạt hiện tại và hai vạch ngang bên cạnh
    public static let medMarkerRing = goldBright.withAlphaComponent(0.28)
    public static let medMarkerRingActive = goldBright.withAlphaComponent(0.72)
    public static let medMarkerTick = goldBright.withAlphaComponent(0.30)

    /// Nút nhấn vàng nhạt trên nền immersive (nền + viền của nút "Xong")
    public static let medGoldTint = goldBright.withAlphaComponent(0.16)
    public static let medGoldTintBorder = goldBright.withAlphaComponent(0.40)

    /// Thẻ / pad trên nền immersive (`--il-med-card`): `#FFFDF8` ở light, trong suốt 4% ở dark.
    public static let medCard = asset("ILMedCard")

    /// Nền rất nhạt của khối segmented control trên nền immersive (`--il-med-04` = medInk 4%).
    public static let medTrackSubtle = medInk.withAlphaComponent(0.04)

    /// Chữ mạnh trên nền immersive (`--il-med-8` = medInk 80%) — nhãn chip chưa chọn.
    public static let medInkStrong = medInk.withAlphaComponent(0.80)

    /// Viền chip đang chọn trên nền immersive (goldBright 50%).
    public static let medGoldChipBorder = goldBright.withAlphaComponent(0.50)

    /// Quầng sáng quanh pad khi gõ mõ / thỉnh chuông (goldBright 32%).
    public static let medGoldHalo = goldBright.withAlphaComponent(0.32)

    /// Vòng sóng lan ra khi gõ mõ (goldBright 55%) / thỉnh chuông (goldBright 60%).
    public static let medGoldRippleMo = goldBright.withAlphaComponent(0.55)
    public static let medGoldRippleBell = goldBright.withAlphaComponent(0.60)

    /// Breathing-ring outlines on the meditation session screen (`--il-med-ring`, `--il-med-ring2`):
    /// `goldDeep` 30% / 42% in light mode, `gold` 25% / 40% in dark mode — the base hue differs per
    /// theme, so these live in their own color sets instead of being alpha variants.
    public static let medRing = asset("ILMedRing")
    public static let medRingStrong = asset("ILMedRingStrong")

    /// Soft halo filling the breathing ring (`--il-med-halo`): `goldBright` 20% light / 28% dark.
    public static let medHalo = asset("ILMedHalo")

    /// Glyph on top of a `medGold` fill (`--il-med-onGold`): `#FFFDF8` light / `#1A1611` dark.
    public static let medOnGold = asset("ILMedOnGold")

    /// Glyphs inside the ghost transport buttons (`--il-med-5`): ink 58% light / 50% dark.
    public static let medInkControl = asset("ILMedInkControl")

    // MARK: - Splash (themed — bộ `--il-spl-*` light/dark của design handoff)
    /// Nền radial màn Splash: kem ấm `#FFFCF4` ở light, đêm `#2A241C` ở dark.
    public static let splashBackgroundTop = asset("ILSplashBackgroundTop")

    /// Điểm kết thúc nền Splash: giấy `#F0E6D4` ở light, đen ấm `#100E0B` ở dark.
    public static let splashBackground = asset("ILSplashBackground")

    /// Wordmark "InnerLamp": `#221E19` ở light, `#F5EEE0` ở dark.
    public static let splashInk = asset("ILSplashInk")

    /// Slogan dưới wordmark (alpha đã nướng vào color set).
    public static let splashInkSub = asset("ILSplashInkSub")

    /// Quầng sáng vàng phía trên màn Splash (gold ở light, goldBright ở dark).
    public static let splashGlow = asset("ILSplashGlow")

    /// Nền radial bên trong vòng đèn màn Splash (gold ở light, goldBright ở dark).
    public static let splashHalo = asset("ILSplashHalo")

    /// Viền vòng đèn màn Splash (goldDeep ở light, gold ở dark).
    public static let splashBorder = asset("ILSplashBorder")

    /// Ba vòng ripple lan ra — nhạt dần theo thứ tự phát (goldDeep/goldBright).
    public static let splashRing = asset("ILSplashRing")
    public static let splashRing2 = asset("ILSplashRing2")
    public static let splashRing3 = asset("ILSplashRing3")

    // MARK: - Logo (IL-Logo)
    /// Vòng ngoài của logo (`--il-logo-ring`): `gold` ở light, `goldBright` ở dark.
    public static let logoRing = asset("ILLogoRing")
    /// Thân ngọn lửa logo (`#E6A94E`) — cố định ở cả hai theme.
    public static let logoFlame = asset("ILLogoFlame")
    /// Lõi ngọn lửa logo (`#F3C673`) — cố định ở cả hai theme.
    public static let logoFlameCore = asset("ILLogoFlameCore")

    /// Tia sáng quét hai bên vòng đèn (gold ở light, goldLight ở dark).
    public static let splashRay = asset("ILSplashRay")
    public static let splashRay2 = asset("ILSplashRay2")

    // MARK: - Temple header (hero "Trang chùa" — bộ `--il-th-*` light/dark của design handoff)
    /// Đỉnh gradient hero Trang chùa (`--il-th-bg` chặng 1) — kem ấm ở light, nâu đêm ở dark.
    public static let templeHeaderTop = asset("ILTempleHeaderTop")

    /// Giữa gradient hero Trang chùa (`--il-th-bg` chặng 2) — tan dần về `canvas`.
    public static let templeHeaderMid = asset("ILTempleHeaderMid")

    /// Chữ chính hero Trang chùa (`--il-th-ink`): `ink` ở light, `inkOnDark` ở dark.
    public static let templeHeaderInk = asset("ILTempleHeaderInk")

    /// Quầng sáng vàng ở đỉnh hero Trang chùa (`--il-th-glow`), alpha đã nướng vào color set.
    public static let templeHeaderGlow = asset("ILTempleHeaderGlow")

    /// Chữ phụ hero Trang chùa (`--il-th-sub`) — 60% của `templeHeaderInk` (design dark dùng ~55%,
    /// chênh lệch không đáng kể nên derive chung 60%).
    public static let templeHeaderSub = templeHeaderInk.withAlphaComponent(0.60)

    // MARK: - Player (themed — bộ `--il-pl-*` light/dark của design handoff)
    /// Tâm gradient nền trình phát (`--il-pl-bg`): kem ấm `#FFFCF4` ở light, đêm `#2A241C` ở dark.
    public static let playerBackgroundCenter = asset("ILPlayerBackgroundCenter")

    /// Mép gradient nền trình phát: giấy `#EFE5D2` ở light, đen ấm `#0F0D0A` ở dark.
    public static let playerBackgroundEdge = asset("ILPlayerBackgroundEdge")

    /// Chữ phụ trên nền trình phát (`--il-pl-sub`) — alpha đã nướng vào color set vì khác nhau giữa
    /// light (ink 58%) và dark (inkOnDark 50%).
    public static let playerSubtitle = asset("ILPlayerSubtitle")

    /// Nền chip chưa chọn trên trình phát (`--il-pl-chip`) — ink 4% light / inkOnDark 7% dark.
    public static let playerChipBackground = asset("ILPlayerChipBackground")

    /// Chữ chip chưa chọn trên trình phát (`--il-pl-chipfg`) — ink 66% light / inkOnDark 60% dark.
    public static let playerChipText = asset("ILPlayerChipText")

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

    /// Dây xỏ tràng hạt — ba sợi đỏ nâu xen kẽ (đậm / trung / sáng)
    public static let beadCordDark = asset("ILBeadCordDark")
    public static let beadCordMid = asset("ILBeadCordMid")
    public static let beadCordLight = asset("ILBeadCordLight")

    /// Bóng đổ và lớp tối/sáng giả inset-shadow của hạt
    public static let beadShadow = UIColor.black.withAlphaComponent(0.55)
    public static let beadShade = UIColor.black.withAlphaComponent(0.55)
    /// Điểm sáng gắt phía trên-trái của hạt (kem 85%) và ánh vàng cam phản chiếu ở rìa dưới-phải.
    public static let beadHighlight = inkOnDark.withAlphaComponent(0.85)
    public static let beadRim = goldBright.withAlphaComponent(0.28)

    // MARK: - Family tree (Gia phả — parchment palette, fixed: does not flip with dark mode)
    /// Colors of the "cây gia phả" illustration (parchment paper, bark, leaves, hexagon medallions).
    /// Fixed like `bead*`: the tree is an illustration, so it keeps one palette in both themes.
    public enum FamilyTree {
        // Paper
        public static let paper = asset("ILTreePaper")
        public static let paperMid = asset("ILTreePaperMid")
        public static let paperEdge = asset("ILTreePaperEdge")
        public static let cream = asset("ILTreeCream")

        // Text
        public static let ink = asset("ILTreeInk")
        public static let inkSecondary = ink.withAlphaComponent(0.70)
        public static let inkTertiary = ink.withAlphaComponent(0.60)
        public static let inkMuted = ink.withAlphaComponent(0.50)
        public static let heading = asset("ILTreeHeading")
        public static let selected = asset("ILTreeSelected")
        public static let labelHalo = paper

        // Lines & surfaces
        public static let bark = asset("ILTreeBark")
        public static let barkLight = asset("ILTreeBarkLight").withAlphaComponent(0.55)
        public static let brown = asset("ILTreeBrown")
        public static let border = brown.withAlphaComponent(0.22)
        public static let borderSoft = brown.withAlphaComponent(0.16)
        public static let divider = brown.withAlphaComponent(0.10)
        public static let grabber = brown.withAlphaComponent(0.28)
        /// Zoom buttons over the canvas: light cream (design `#FBF6EA` @ 94%) with a 25% brown border
        public static let controlSurface = creamLight.withAlphaComponent(0.94)
        public static let controlBorder = brown.withAlphaComponent(0.25)
        public static let scrim = ink.withAlphaComponent(0.22)
        public static let shadow = ink

        // Status / roles
        public static let forest = asset("ILTreeForest")
        public static let forestLight = asset("ILTreeForestLight")
        public static let livingTint = forestLight.withAlphaComponent(0.18)
        public static let deceasedTint = brown.withAlphaComponent(0.14)
        public static let seal = asset("ILTreeSeal")
        /// Book-switcher seals: the mother's book and the merged "nội – ngoại" view.
        public static let sealMaternal = asset("ILTreeSealMaternal")
        public static let sealMerged = asset("ILTreeSealMerged")
        public static let gold = asset("ILTreeGold")
        public static let founderGold = asset("ILTreeFounderGold")
        public static let eyebrow = asset("ILTreeSelected")
        public static let halo = gold.withAlphaComponent(0.60)
        public static let canopyGlow = forestLight.withAlphaComponent(0.26)
        public static let groundShadow = brown.withAlphaComponent(0.22)

        // Leaves
        public static let leafDark = asset("ILTreeLeafDark")
        public static let leafMid = asset("ILTreeLeafMid")
        public static let leafLight = asset("ILTreeLeafLight")

        // Medallion
        public static let skin = asset("ILTreeSkin")
        public static let hair = asset("ILTreeHair")
        public static let plateLiving = asset("ILTreePlateLiving")
        public static let plateDeceased = asset("ILTreePlateDeceased")
        public static let plateFounder = asset("ILTreePlateFounder")
        public static let garmentFemale = asset("ILTreeGarmentFemale")
        public static let garmentFounder = asset("ILTreeGarmentFounder")
        public static let garmentFemaleDeceased = asset("ILTreeGarmentFemaleDeceased")
        public static let garmentMaleLiving = forest
        public static let garmentMaleDeceased = asset("ILTreeGarmentMaleDeceased")
        /// Collar notch under the chin (cream, 55%)
        public static let collarNotch = cream.withAlphaComponent(0.55)
        /// Hair stripe tone over `hair` (male bust)
        public static let hairStripe = bark

        // Medallion gradients (top → bottom of the plate, 135° for the trim) and tick rings
        public static let founderTrimStops = [asset("ILTreeFounderTrimLight"), founderGold, asset("ILTreeFounderTrimEnd")]
        public static let headTrimStops = [leafDark, asset("ILTreeHeadTrimDark")]
        public static let plateFounderGradient = [asset("ILTreePlateFounderTop"), plateFounder]
        public static let plateLivingGradient = [asset("ILTreePlateLivingTop"), plateLiving]
        public static let plateDeceasedGradient = [asset("ILTreePlateDeceasedTop"), plateDeceased]
        /// Tick ring: (dark segment, light segment)
        public static let ticksFounder = (dark: asset("ILTreeTickFounderDark"), light: asset("ILTreeTickFounderLight"))
        public static let ticksLiving = (dark: forestLight, light: asset("ILTreeTickLivingLight"))
        public static let ticksDeceased = (dark: asset("ILTreeTickDeceasedDark"), light: paperMid)
        /// Founder hexagon in the legend (135° gradient)
        public static let legendFounderStops = [asset("ILTreeFounderGoldBright"), founderGold]

        // Header, chips, search field, canvas paper
        public static let creamLight = asset("ILTreeCreamLight")
        public static let fieldSurface = creamLight.withAlphaComponent(0.92)
        public static let chipSurface = creamLight.withAlphaComponent(0.75)
        public static let cardSurface = creamLight.withAlphaComponent(0.90)
        public static let searchPlaceholder = bark.withAlphaComponent(0.45)
        public static let searchButtonActive = brown.withAlphaComponent(0.12)
        public static let addButtonShadow = forest.withAlphaComponent(0.80)
        public static let grainFine = brown.withAlphaComponent(0.06)
        public static let grainCoarse = brown.withAlphaComponent(0.04)
        public static let paperBlob = forestLight.withAlphaComponent(0.22)
        public static let canvasTopBorder = brown.withAlphaComponent(0.16)
        /// Selected row of the add-member relative picker
        public static let pickerSelectedRow = gold.withAlphaComponent(0.18)

        // Detail sheet extras
        public static let sheetHighlight = UIColor.white.withAlphaComponent(0.6)
        public static let memorialGlyphTint = seal.withAlphaComponent(0.10)
        public static let memorialGlyphRing = seal.withAlphaComponent(0.28)
        public static let cardRing = brown.withAlphaComponent(0.18)
        public static let outlineButtonBorder = forest.withAlphaComponent(0.45)
        public static let reminderButtonBorder = forest.withAlphaComponent(0.40)
        public static let linkUnderline = selected.withAlphaComponent(0.35)
        public static let flameStops = [asset("ILTreeFlameTop"), asset("ILTreeFlameBottom")]

        // Viewer ("BẠN") marker — gold pill, zoom button and legend badge
        public static let me = asset("ILTreeMe")
        public static let inkOnMe = asset("ILTreeInkOnMe")
        public static let meRelation = asset("ILTreeSelected")
    }

    // MARK: - Borders
    /// Viền thẻ tiêu chuẩn (alpha 0.08 của `ink`)
    public static let border = ink.withAlphaComponent(0.08)

    /// Hairline under a sticky header strip (`--il-ink-06`, alpha 0.06 of `ink`)
    public static let borderSoft = ink.withAlphaComponent(0.06)

    /// Viền nút ghost, input active (alpha 0.18 của `ink`)
    public static let borderStrong = ink.withAlphaComponent(0.18)

    /// Outline of small pill buttons on cards (`--il-ink-16`, alpha 0.16 of `ink`)
    public static let borderPill = ink.withAlphaComponent(0.16)

    /// Fill of the round "×" clear button inside a search field (`--il-ink-12`, alpha 0.12 of `ink`)
    public static let searchClearFill = ink.withAlphaComponent(0.12)

    /// Border of labeled input cards (`--il-ink-1`, alpha 0.10 of `ink`)
    public static let borderMedium = ink.withAlphaComponent(0.10)

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

    /// Blurred pill laid over a cover photo (alpha 0.42 of `scrim`) — "Sửa hồ sơ" on the Profile cover
    public static let coverPill = scrim.withAlphaComponent(0.42)

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

    /// Alpha variants used only by the loading placeholders (`ILSkeletonLoadingView`,
    /// `ILLoadMoreFooterView`). All derive from theme-aware bases, so they flip with dark mode.
    public enum Skeleton {
        /// Hero block (`--il-ink-07`)
        public static let blockStrong = ILColors.ink.withAlphaComponent(0.07)
        /// Title bar + row icon tile (`--il-ink-08`)
        public static let bar = ILColors.ink.withAlphaComponent(0.08)
        /// Row primary line (`--il-ink-09`)
        public static let line = ILColors.ink.withAlphaComponent(0.09)
        /// Tiles + row secondary line (`--il-ink-06`)
        public static let lineSoft = ILColors.ink.withAlphaComponent(0.06)
        /// Row card background (`--il-card-70`)
        public static let rowBackground = ILColors.surface.withAlphaComponent(0.70)
        /// Lamp ring around the pulsing dot (gold, alpha 0.55)
        public static let lampRing = ILColors.gold.withAlphaComponent(0.55)
        /// Load-more spinner track (`--il-ink-12`)
        public static let spinnerTrack = ILColors.ink.withAlphaComponent(0.12)
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

    // MARK: - Reader themes (Tụng kinh — "Vàng cát" and "Đen OLED" reading backgrounds)
    /// Fixed palettes for the two non-default reading backgrounds of the Reader screen. The default
    /// theme reuses the adaptive `canvasWarm` / `ink` / `surface` tokens, so it is not listed here.
    /// Both themes keep one look in light and dark mode: the user picks them explicitly.
    public enum Reader {
        public static let sandBackground = asset("ILReaderSandBackground")
        public static let sandInk = asset("ILReaderSandInk")
        public static let sandPanel = asset("ILReaderSandPanel")
        public static let oledBackground = asset("ILReaderOLEDBackground")
        public static let oledInk = asset("ILReaderOLEDInk")
        public static let oledPanel = asset("ILReaderOLEDPanel")
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
