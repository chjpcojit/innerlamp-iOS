//
//  ILMetrics.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

public enum ILMetrics {
    
    // MARK: - Spacing & Margins
    /// Khoảng cách lề màn hình tổng thể (top: 66, left: 20, bottom: 30, right: 20)
    public static let screenPadding = UIEdgeInsets(top: 66, left: 20, bottom: 30, right: 20)
    
    /// Lề ngang màn hình tiêu chuẩn (20px)
    public static let screenHorizontal: CGFloat = 20.0
    
    /// Khoảng cách giữa các nhóm section (20px, khoảng 18–24px)
    public static let groupSpacing: CGFloat = 20.0
    
    /// Khoảng cách giữa các hàng trong nhóm (10px)
    public static let rowSpacing: CGFloat = 10.0

    /// Độ thụt trái của bình luận trả lời lồng (22px) ở màn Bài đăng đạo tràng (`indent: 22px`).
    public static let commentIndent: CGFloat = 22.0
    
    /// Khoảng cách nhỏ (6–8px)
    public static let spaceSmall: CGFloat = 8.0
    
    /// Khoảng cách trung bình (12–16px)
    public static let spaceMedium: CGFloat = 14.0
    
    /// Khoảng cách chuẩn giữa các khối (16px)
    public static let spaceStandard: CGFloat = 16.0

    /// Khoảng cách lớn (24–32px)
    public static let spaceLarge: CGFloat = 28.0

    /// Lề ngang của các màn immersive (Phiên thiền, Niệm Phật...) — rộng hơn màn thường (26px)
    public static let immersiveHorizontal: CGFloat = 26.0

    /// Gap between the breathing ring and the breath cue on the meditation session screen (34px)
    public static let immersiveCueSpacing: CGFloat = 34.0

    /// Breathing ring on the meditation session screen: outer diameter (264px), inset of the inner
    /// outlined ring (26px) and of the innermost halo (62px).
    public static let breathingRingDiameter: CGFloat = 264.0
    public static let breathingRingInnerInset: CGFloat = 26.0
    public static let breathingRingCoreInset: CGFloat = 62.0

    /// Immersive transport controls: ghost side buttons (50px), gold primary button (78px) and the
    /// gap between them (22px).
    public static let transportSideButtonSize: CGFloat = 50.0
    public static let transportPrimaryButtonSize: CGFloat = 78.0
    public static let transportSpacing: CGFloat = 22.0
    
    // MARK: - Corner Radii
    /// Nút bấm tròn dạng Pill, Chip (999px)
    public static let radiusPill: CGFloat = 999.0
    
    /// Thẻ lớn, modal sheet (24px)
    public static let radiusCardLarge: CGFloat = 24.0
    
    /// Hàng danh sách, thẻ nhỏ (18px)
    public static let radiusCardSmall: CGFloat = 18.0

    /// Thẻ trung bình giữa `radiusCardSmall` và `radiusCardLarge` (22px — vd. thẻ nhịp màn Chuông mõ)
    public static let radiusCardMedium: CGFloat = 22.0

    /// Standard content card (20px — e.g. stat tiles and chart cards on Stats)
    public static let radiusCardRegular: CGFloat = 20.0
    
    /// Ô nhập liệu Input Field (14px)
    public static let radiusInput: CGFloat = 14.0

    /// Labeled input card / small action card (16px)
    public static let radiusField: CGFloat = 16.0
    
    /// Khung icon tile (13px)
    public static let radiusIconTile: CGFloat = 13.0
    
    /// Bo góc biểu tượng nhỏ (2px)
    public static let radiusGlyph: CGFloat = 2.0

    /// Bo góc ô icon đầu section (7px — 30% của `sectionIconSize`, như `IL-Icon` trong prototype)
    public static let radiusSectionIcon: CGFloat = 7.0

    /// Bo góc ô icon lớn (14px — 30% của `iconTileLargeSize`, thẻ Chuông mõ ở Trang chủ)
    public static let radiusIconTileLarge: CGFloat = 14.0

    /// Selectable option tile in a settings panel (10px — Reader font-size / background tiles)
    public static let radiusOptionTile: CGFloat = 10.0

    /// Highlight behind the chanted line on the Reader screen (6px)
    public static let radiusLineHighlight: CGFloat = 6.0
    
    // MARK: - Heights & Dimensions
    /// Chiều cao nút bấm tiêu chuẩn (50px)
    public static let buttonHeight: CGFloat = 50.0
    
    /// Chiều cao ô nhập liệu (48px)
    public static let inputHeight: CGFloat = 48.0

    /// Round "×" clear button inside `ILSearchInputView` (20x20 in the prototype)
    public static let searchClearSize: CGFloat = 20.0
    
    /// Chiều cao hàng danh sách (72px)
    public static let rowHeight: CGFloat = 72.0
    
    /// Kích thước ô icon tile (44x44px)
    public static let iconTileSize: CGFloat = 44.0

    /// Ô icon đầu hàng `ILSettingRow` (34x34px, `IL-Icon size="34"` trong `IL-SettingRow`)
    public static let settingIconTileSize: CGFloat = 34.0

    /// Bo góc ô icon của `ILSettingRow` (10px — 30% của `settingIconTileSize`)
    public static let radiusSettingIconTile: CGFloat = 10.0

    /// Ô icon đầu section (22x22px) — `ILSectionHeaderView` có icon
    public static let sectionIconSize: CGFloat = 22.0

    /// Ô icon lớn (46x46px) — thẻ Chuông mõ ở Trang chủ
    public static let iconTileLargeSize: CGFloat = 46.0
    
    /// Chiều cao thanh điều hướng đáy bao gồm safe area (110px)
    public static let bottomNavHeight: CGFloat = 110.0

    /// Chiều cao 1 ô nhập số trong mã OTP (58px)
    public static let otpDigitBoxHeight: CGFloat = 58.0

    /// Blur strength (0...1) of a sticky detail-screen header once the content has scrolled fully under it
    /// ("just enough", not fully frosted). Used by `ILHeaderBlurView` — chi tiết chùa, Phật/Bồ Tát, bài viết, kinh sách.
    public static let headerBlurMaxIntensity: CGFloat = 0.7

    /// Opacity of a sticky header's canvas tint once it is fully "glass" (content scrolled under it).
    /// Used by `ILStickyHeaderBand`; lower = more of the scrolled content shows through.
    public static let headerGlassTintAlpha: CGFloat = 0.3

    /// Scroll distance (pt) over which a plain sticky header goes from flat to full glass.
    public static let headerBlurFadeDistance: CGFloat = 40

    // MARK: - Shadow Helpers
    public struct Shadow {
        public let color: UIColor
        public let alpha: Float
        public let x: CGFloat
        public let y: CGFloat
        public let blur: CGFloat
        public let spread: CGFloat
        
        public init(color: UIColor, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat = 0) {
            self.color = color
            self.alpha = alpha
            self.x = x
            self.y = y
            self.blur = blur
            self.spread = spread
        }
        
        public func apply(to layer: CALayer) {
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = alpha
            layer.shadowOffset = CGSize(width: x, height: y)
            layer.shadowRadius = blur / 2.0
            if spread == 0 {
                layer.shadowPath = nil
            } else {
                let dx = -spread
                let rect = layer.bounds.insetBy(dx: dx, dy: dx)
                layer.shadowPath = UIBezierPath(rect: rect).cgPath
            }
        }
    }
    
    /// Đổ bóng nút primary (0 8px 24px rgba(34,30,25,.16))
    public static let shadowPrimaryButton = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.16, x: 0, y: 8, blur: 24)
    
    /// Đổ bóng nút gold (0 8px 24px rgba(184,134,47,.24))
    public static let shadowGoldButton = Shadow(color: UIColor(hex: "#B8862F"), alpha: 0.24, x: 0, y: 8, blur: 24)

    /// Đổ bóng nút play/pause vàng tròn màn Chuông mõ (0 8px 24px rgba(217,150,60,.28))
    public static let shadowGoldToggle = Shadow(color: ILColors.goldBright, alpha: 0.28, x: 0, y: 8, blur: 24)
    
    /// Đổ bóng thanh phát nổi / card nổi (0 6px 20px rgba(34,30,25,.07))
    public static let shadowFloatingBar = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.07, x: 0, y: 6, blur: 20)

    /// Bóng nhẹ dưới tab đang chọn của segmented control (0 1px 3px rgba(34,30,25,.08)) — khớp
    /// `box-shadow` của tab đang chọn ở màn Thiền định trong design handoff.
    public static let shadowSegmentSelected = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.08, x: 0, y: 1, blur: 3)
    
    /// Upward shadow of the bottom nav bar in light mode (0 -8px 24px rgba(34,30,25,.04))
    public static let shadowBottomNav = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.04, x: 0, y: -8, blur: 24)

    /// Đổ bóng nút đèn ở thanh đáy sáng (0 6px 16px rgba(184,134,47,.35))
    public static let shadowLampLight = Shadow(color: UIColor(hex: "#B8862F"), alpha: 0.35, x: 0, y: 6, blur: 16)
    
    /// Đổ bóng nút đèn ở thanh đáy tối (0 0 28px rgba(217,150,60,.45))
    public static let shadowLampDark = Shadow(color: UIColor(hex: "#D9963C"), alpha: 0.45, x: 0, y: 0, blur: 28)

    /// Glow under the gold primary button of an immersive screen in light mode
    /// (`--il-med-glow`: 0 8px 26px rgba(138,90,24,.28))
    public static let shadowMedGoldLight = Shadow(color: ILColors.goldDeep, alpha: 0.28, x: 0, y: 8, blur: 26)

    /// Glow under the gold primary button of an immersive screen in dark mode
    /// (`--il-med-glow`: 0 0 44px rgba(217,150,60,.5))
    public static let shadowMedGoldDark = Shadow(color: ILColors.goldBright, alpha: 0.50, x: 0, y: 0, blur: 44)

    // MARK: - Alert / Error Popups
    /// Light toast (0 14px 34px ink .18)
    public static let shadowToast = Shadow(color: ILColors.Alert.toastShadow, alpha: 0.18, x: 0, y: 14, blur: 34)

    /// Dark action banner (0 16px 38px rgba(20,16,12,.32))
    public static let shadowAlertBanner = Shadow(color: ILColors.scrim, alpha: 0.32, x: 0, y: 16, blur: 38)

    /// Snackbar (0 16px 34px rgba(20,16,12,.34))
    public static let shadowSnackbar = Shadow(color: ILColors.scrim, alpha: 0.34, x: 0, y: 16, blur: 34)

    /// Error bottom sheet, cast upwards (0 -18px 46px rgba(20,16,12,.28))
    public static let shadowAlertSheet = Shadow(color: ILColors.scrim, alpha: 0.28, x: 0, y: -18, blur: 46)

    /// Center error dialog (0 22px 54px rgba(20,16,12,.34))
    public static let shadowAlertDialog = Shadow(color: ILColors.scrim, alpha: 0.34, x: 0, y: 22, blur: 54)

    /// Sizes & spacing shared by the error popups in `Components/Alert/`.
    public enum Alert {
        /// Horizontal inset of toast / banner / snackbar from the screen edges
        public static let floatingInset: CGFloat = 14
        /// Gap between the safe-area top and the toast / banner
        public static let topOffset: CGFloat = 7
        /// Gap between the safe-area bottom and the snackbar
        public static let bottomOffset: CGFloat = 0
        /// Corner radius of the snackbar
        public static let snackbarRadius: CGFloat = 16
        /// Top-corner radius of the error bottom sheet
        public static let sheetRadius: CGFloat = 28
        /// Max width of the center dialog
        public static let dialogMaxWidth: CGFloat = 312
        /// Min margin between the center dialog and the screen edges
        public static let dialogMargin: CGFloat = 26
        /// Max width of the message paragraph on the full-screen error
        public static let fullMessageMaxWidth: CGFloat = 290

        /// "!" badge on toast / banner
        public static let glyphSmall: CGFloat = 26
        /// "!" badge on dialog
        public static let glyphDialog: CGFloat = 52
        /// "!" badge on bottom sheet
        public static let glyphSheet: CGFloat = 54
        /// Inner "!" badge on the full-screen error
        public static let glyphFull: CGFloat = 34
        /// Outer ring around the full-screen glyph
        public static let glyphRingFull: CGFloat = 96

        /// Tap target of the toast close "×"
        public static let closeSmall: CGFloat = 24
        /// Round close button on the full-screen error
        public static let closeLarge: CGFloat = 34

        /// Sheet grabber
        public static let grabberSize = CGSize(width: 38, height: 4)
        /// Status dot on the snackbar
        public static let snackbarDot: CGFloat = 7
        /// Countdown bar at the bottom of the auto-dismissing toast
        public static let countdownBarHeight: CGFloat = 2

        /// Compact pill on the banner (vertical, horizontal padding)
        public static let bannerButtonPadding = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        /// Pill height on the dialog
        public static let dialogButtonHeight: CGFloat = 44
        /// Pill height on the full-screen error
        public static let fullButtonHeight: CGFloat = 48
    }

    /// Sizes, radii and animation timing of the loading placeholders
    /// (`ILSkeletonLoadingView`, `ILLoadMoreFooterView`).
    public enum Skeleton {
        /// Lamp ring next to the "Lighting the lamp…" caption
        public static let lampRingSize: CGFloat = 22
        /// Lamp ring border width
        public static let lampRingBorder: CGFloat = 1.4
        /// Gold dot inside the lamp ring
        public static let lampDotSize: CGFloat = 7
        /// Gap between the lamp ring and the caption
        public static let captionSpacing: CGFloat = 12
        /// Gap between the caption row and the title bar
        public static let captionBottomSpacing: CGFloat = 24
        /// Vertical gap between skeleton blocks
        public static let blockSpacing: CGFloat = 18

        /// Title bar height / corner radius / width ratio of the container
        public static let titleBarHeight: CGFloat = 30
        public static let titleBarRadius: CGFloat = 10
        public static let titleBarWidthRatio: CGFloat = 0.62
        /// Hero block height
        public static let heroHeight: CGFloat = 170
        /// Two side-by-side tiles height
        public static let tileHeight: CGFloat = 86

        /// Placeholder row inner padding (vertical, horizontal)
        public static let rowPadding = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        /// Placeholder row primary / secondary line heights
        public static let rowLineHeight: CGFloat = 11
        public static let rowSubLineHeight: CGFloat = 9
        /// Corner radius of the row lines
        public static let rowLineRadius: CGFloat = 6
        /// Placeholder pill button (e.g. the "Chọn" pill of a temple row)
        public static let rowPillWidth: CGFloat = 56
        public static let rowPillHeight: CGFloat = 30
        /// Width ratio of the row secondary line
        public static let rowSubLineWidthRatio: CGFloat = 0.44
        /// Width ratios of the primary line for each of the 4 rows
        public static let rowLineWidthRatios: [CGFloat] = [0.68, 0.54, 0.72, 0.46]

        /// `ilpulse` — opacity .55 ↔ .95 over 1.6s, blocks staggered
        public static let pulseDuration: TimeInterval = 1.6
        public static let pulseMinOpacity: Float = 0.55
        public static let pulseMaxOpacity: Float = 0.95
        /// Opacity used instead of the pulse when Reduce Motion is on
        public static let pulseStaticOpacity: Float = 0.75
        /// Pulse delay of the hero block and the two tiles (title bar starts at 0)
        public static let heroPulseDelay: TimeInterval = 0.15
        public static let tilePulseDelays: [TimeInterval] = [0.25, 0.35]
        /// Stagger step between consecutive placeholder rows
        public static let rowPulseDelayStep: TimeInterval = 0.1

        /// Load-more spinner diameter / ring width / one full turn
        public static let spinnerSize: CGFloat = 14
        public static let spinnerLineWidth: CGFloat = 2
        public static let spinnerRotationDuration: TimeInterval = 0.9
        /// Load-more footer vertical padding (top, bottom)
        public static let footerPadding = UIEdgeInsets(top: 20, left: 0, bottom: 4, right: 0)
    }

    /// Geometry of the family-tree canvas and detail sheet (`Scenes/FamilyTree`). Canvas values are
    /// in points at zoom 1.0.
    public enum FamilyTree {
        // Canvas layout
        /// Horizontal room given to one leaf member
        public static let slotWidth: CGFloat = 84
        /// Extra width reserved to the right of a member that has a spouse
        public static let spouseOffsetX: CGFloat = 76
        /// Spouse sits a little lower than their partner
        public static let spouseOffsetY: CGFloat = 26
        /// Vertical distance between two generations
        public static let generationGap: CGFloat = 128
        /// Room above the newest generation / left+right of the widest row
        public static let canvasTopInset: CGFloat = 70
        public static let canvasSideInset: CGFloat = 40
        /// Trunk and roots below the founder's generation
        public static let canvasBottomInset: CGFloat = 200
        /// Minimum canvas width, so a tiny tree still fills the screen
        public static let canvasMinWidth: CGFloat = 390

        // Zoom
        public static let zoomLevels: [CGFloat] = [0.7, 1, 1.35]
        public static let defaultZoomIndex = 1

        // Branches: stroke width per generation (2…7+), thicker near the root; generation 7 and deeper = 2.6
        public static let branchWidths: [CGFloat] = [16, 11, 7.5, 5, 3.4, 2.6]
        public static let branchHighlightRatio: CGFloat = 0.35
        public static let lineageMinWidth: CGFloat = 2.2
        public static let lineageWidthRatio: CGFloat = 0.38
        public static let spouseLineWidth: CGFloat = 1.8
        public static let spouseDash: [NSNumber] = [4, 4]
        public static let trunkWidth: CGFloat = 5
        public static let leafRadiusX: CGFloat = 8
        public static let leafRadiusY: CGFloat = 3.4

        // Nodes (hexagon medallion width; height = width × hexRatio)
        public static let hexRatio: CGFloat = 1.15
        public static let nodeFounderWidth: CGFloat = 80
        public static let nodeHeadWidth: CGFloat = 62
        public static let nodeSpouseWidth: CGFloat = 46
        public static let nodeYoungestWidth: CGFloat = 48
        public static let nodeWidth: CGFloat = 52
        public static let nodeLabelWidth: CGFloat = 130
        public static let nodeLabelGap: CGFloat = 4
        public static let haloRatio: CGFloat = 1.9
        public static let dimmedAlpha: CGFloat = 0.25
        public static let searchDimmedAlpha: CGFloat = 0.2
        public static let sealSize: CGFloat = 20
        public static let livingDotSize: CGFloat = 8

        // Hexagon medallion layers (inset from the outer edge)
        public static let medallionCreamInset: CGFloat = 2
        public static let medallionTicksInset: CGFloat = 4
        public static let medallionInnerCreamInset: CGFloat = 6
        public static let medallionPlateInset: CGFloat = 7.5

        // Header
        public static let headerInset: CGFloat = 16
        public static let headerLeadingInset: CGFloat = 10
        public static let headerTopPadding: CGFloat = 8
        public static let headerGap: CGFloat = 10
        public static let headerBackSize = CGSize(width: 40, height: 44)
        public static let headerSealSize: CGFloat = 34
        public static let headerSealRadius: CGFloat = 5
        public static let headerSealRotation: CGFloat = -4
        public static let headerButtonSize: CGFloat = 44
        public static let headerTitleGap: CGFloat = 6
        public static let headerChevronSize: CGFloat = 14
        public static let chipPaddingH: CGFloat = 14
        public static let chipRowTopSpacing: CGFloat = 12
        public static let legendInset: CGFloat = 20
        public static let legendTopSpacing: CGFloat = 10
        public static let legendGap: CGFloat = 12

        // Book switcher menu
        public static let switcherInset: CGFloat = 12
        public static let switcherTopGap: CGFloat = 4
        public static let switcherRadius: CGFloat = 20
        public static let switcherPadding: CGFloat = 8
        public static let switcherRowRadius: CGFloat = 14
        public static let switcherRowHeight: CGFloat = 60
        public static let switcherLinkRowHeight: CGFloat = 52
        public static let switcherSealSize: CGFloat = 36
        public static let switcherSealRadius: CGFloat = 6
        public static let switcherShadowBlur: CGFloat = 20
        public static let switcherShadowOffsetY: CGFloat = 18

        // Node extras
        public static let sealRadius: CGFloat = 3
        public static let sealRotation: CGFloat = -8
        public static let sealRingInset: CGFloat = 2
        public static let nodeEndedLineSize = CGSize(width: 10, height: 1.5)
        public static let nodeEndedGap: CGFloat = 5
        public static let nodeEndedTopSpacing: CGFloat = 3
        /// Padding around a halo label so its stacked glow is not clipped
        public static let labelHaloPadding: CGFloat = 10
        public static let labelHaloBlurs: [CGFloat] = [3, 6, 10]

        // Viewer ("BẠN") marker
        public static let mePillSize = CGSize(width: 42, height: 18)
        /// Gap between the pill's bottom edge and the medallion's top edge
        public static let mePillGap: CGFloat = 4
        public static let mePillRingWidth: CGFloat = 2
        public static let legendMePillHeight: CGFloat = 11
        public static let legendMePillPaddingH: CGFloat = 4
        public static let controlIconSize: CGFloat = 18

        // Medallion bust
        public static let tickCount = 72

        // Controls
        public static let controlSize: CGFloat = 44
        public static let controlRadius: CGFloat = 14
        public static let controlSpacing: CGFloat = 6
        /// Zoom button shadow: blur radius, vertical offset and inset (CSS spread -6)
        public static let controlShadowBlur: CGFloat = 5
        public static let controlShadowOffsetY: CGFloat = 4
        public static let controlShadowSpread: CGFloat = 6
        public static let controlInset: CGFloat = 14
        public static let chipHeight: CGFloat = 34

        // Detail sheet
        public static let sheetCollapsedHeight: CGFloat = 132
        public static let sheetExpandedRatio: CGFloat = 0.78
        public static let sheetHeaderMedallion = CGSize(width: 56, height: 64)
        public static let sheetRelationRowHeight: CGFloat = 44
        public static let sheetKeyColumnWidth: CGFloat = 84
        public static let sheetRelationKeyWidth: CGFloat = 64
        public static let sheetGrabberSize = CGSize(width: 36, height: 4)
        public static let sheetChevronStroke: CGFloat = 2.2
        public static let sheetCardRadius: CGFloat = 6
        public static let sheetPillHeight: CGFloat = 44
        public static let sheetCTAHeight: CGFloat = 48
        public static let sheetTileMinHeight: CGFloat = 64
        public static let sheetMemorialGlyphSize: CGFloat = 44
        public static let sheetAnimationDuration: TimeInterval = 0.32
        /// Bottom scroll room so the collapsed sheet never covers the lowest node
        public static let sheetScrollMargin: CGFloat = 150
        /// Room kept around the outermost people (crown of leaves above, name label below) when centring the tree
        public static let peopleSpanPaddingTop: CGFloat = 60
        public static let peopleSpanPaddingBottom: CGFloat = 50
    }
}
