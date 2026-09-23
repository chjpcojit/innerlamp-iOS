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
    
    // MARK: - Corner Radii
    /// Nút bấm tròn dạng Pill, Chip (999px)
    public static let radiusPill: CGFloat = 999.0
    
    /// Thẻ lớn, modal sheet (24px)
    public static let radiusCardLarge: CGFloat = 24.0
    
    /// Hàng danh sách, thẻ nhỏ (18px)
    public static let radiusCardSmall: CGFloat = 18.0
    
    /// Ô nhập liệu Input Field (14px)
    public static let radiusInput: CGFloat = 14.0
    
    /// Khung icon tile (13px)
    public static let radiusIconTile: CGFloat = 13.0
    
    /// Bo góc biểu tượng nhỏ (2px)
    public static let radiusGlyph: CGFloat = 2.0
    
    // MARK: - Heights & Dimensions
    /// Chiều cao nút bấm tiêu chuẩn (50px)
    public static let buttonHeight: CGFloat = 50.0
    
    /// Chiều cao ô nhập liệu (48px)
    public static let inputHeight: CGFloat = 48.0
    
    /// Chiều cao hàng danh sách (72px)
    public static let rowHeight: CGFloat = 72.0
    
    /// Kích thước ô icon tile (44x44px)
    public static let iconTileSize: CGFloat = 44.0
    
    /// Chiều cao thanh điều hướng đáy bao gồm safe area (110px)
    public static let bottomNavHeight: CGFloat = 110.0
    
    /// Chiều cao header tiêu chuẩn (48px)
    public static let headerHeight: CGFloat = 48.0

    /// Chiều cao 1 ô nhập số trong mã OTP (58px)
    public static let otpDigitBoxHeight: CGFloat = 58.0
    
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
    
    /// Đổ bóng thanh phát nổi / card nổi (0 6px 20px rgba(34,30,25,.07))
    public static let shadowFloatingBar = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.07, x: 0, y: 6, blur: 20)
    
    /// Đổ bóng nút đèn ở thanh đáy sáng (0 8px 20px rgba(34,30,25,.28))
    public static let shadowLampLight = Shadow(color: UIColor(hex: "#221E19"), alpha: 0.28, x: 0, y: 8, blur: 20)
    
    /// Đổ bóng nút đèn ở thanh đáy tối (0 0 28px rgba(217,150,60,.45))
    public static let shadowLampDark = Shadow(color: UIColor(hex: "#D9963C"), alpha: 0.45, x: 0, y: 0, blur: 28)

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
}
