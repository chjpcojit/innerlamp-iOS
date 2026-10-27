//
//  ILOtpStateModel.swift
//  InnerLamp
//

import Foundation

/// UI-only state cho màn Xác thực OTP — sống ở Presentation, không phải Domain (không UIKit,
/// không business logic). `ViewController` chỉ đọc field lỗi/trạng thái để hiển thị UI, không
/// tự validate. Owned và mutated exclusively bởi `ILOtpViewModel`.
struct ILOtpStateModel {
    /// EN: Where the code was sent ("Đã gửi tới <email>", criterion 20).
    /// VI: Nơi mã được gửi tới ("Đã gửi tới <email>", tiêu chí 20).
    var email: String = ""
    var code: String = ""
    var codeError: String?
    /// Lỗi khi gửi lại mã (vd: gửi quá sớm) — hiển thị như alert, tách khỏi
    /// `codeError` để không tô đỏ ô nhập mã.
    var resendError: String?

    /// `true` trong lúc `ILOtpUseCase.verifyCode` đang chạy — chuyển `ILButton` sang `.loading`.
    var isVerifying: Bool = false
    /// `true` trong lúc `ILOtpUseCase.resendCode` đang chạy.
    var isResending: Bool = false

    /// Số giây còn lại trước khi được bấm "Gửi lại" — khởi tạo và đếm lại bằng
    /// `resend_after_seconds` từ server, đếm ngược bởi `ILOtpViewModel`.
    var secondsRemaining: Int = ILOtpStateModel.defaultResendCooldownSeconds

    /// Thời gian mã còn hiệu lực — `expires_in_seconds` từ server, dùng cho câu hiển thị hạn mã.
    var otpExpiresInSeconds: Int = ILOtpStateModel.defaultOTPExpirySeconds

    static let codeLength = 6
    /// Giá trị dự phòng, chỉ dùng cho luồng vào màn này mà chưa có response từ server
    /// (ForgotPassword chưa implement). Khớp mặc định đã xác nhận của server.
    static let defaultOTPExpirySeconds = 90
    static let defaultResendCooldownSeconds = 60

    var isCodeComplete: Bool { code.count == Self.codeLength }
    var isSubmitEnabled: Bool { isCodeComplete && !isVerifying }
    var canResend: Bool { secondsRemaining <= 0 && !isResending }

    /// Câu "Mã có hiệu lực trong …" dựng từ `expires_in_seconds` thật của server.
    var expiryText: String {
        String(format: "otp.expiry".localized, Self.durationText(for: otpExpiresInSeconds))
    }

    private static func durationText(for seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60

        if minutes > 0 && remainder > 0 {
            return String(format: "otp.expiry.minutesSeconds".localized, minutes, remainder)
        }
        if minutes > 0 {
            return String(format: "otp.expiry.minutes".localized, minutes)
        }
        return String(format: "otp.expiry.seconds".localized, remainder)
    }

    static let initial = ILOtpStateModel()
}
