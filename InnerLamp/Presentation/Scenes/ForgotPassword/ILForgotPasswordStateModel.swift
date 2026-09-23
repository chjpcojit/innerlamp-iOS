//
//  ILForgotPasswordStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state for the ForgotPassword screen — Presentation layer, owned and mutated exclusively by
/// `ILForgotPasswordViewModel`. No UIKit import, no business logic — `ViewController` only reads
/// this to render, never validates or mutates it directly.
struct ILForgotPasswordStateModel: Equatable {
    var method: ILForgotPasswordMethod = .phone

    /// Mã vùng đang chọn cho `ILPhoneField` — cùng control dùng ở Đăng nhập/Đăng ký, mặc định
    /// Việt Nam (`+84`) khớp design handoff.
    var selectedCountry: ILCountry = .default

    /// Số điện thoại đầy đủ (mã vùng + số quốc gia) — gõ trực tiếp vào `ILPhoneField` (người dùng
    /// chưa đăng nhập nên app không có sẵn số này), dùng để gửi hướng dẫn và chuyển tiếp sang OTP.
    var fullPhone: String = ""
    /// Phần số quốc gia người dùng đã gõ (không gồm mã vùng) — giữ riêng để đổi mã vùng không
    /// làm mất số đã nhập.
    var nationalPhone: String = ""
    /// Email đầy đủ đã đăng ký — dùng để gửi hướng dẫn.
    var fullEmail: String = ""

    /// Lỗi chung từ server/network (vd: không gửi được hướng dẫn) — hiển thị qua `showError`.
    var submitError: String?

    /// `true` trong lúc `ILForgotPasswordUseCase.sendResetInstructions` đang chạy — dùng để
    /// chuyển `ILButton` sang `.loading`.
    var isSubmitting: Bool = false

    /// Giá trị đầy đủ tương ứng với `method` đang chọn — nội dung thực sự sẽ nhận hướng dẫn.
    var selectedContact: String {
        method == .phone ? fullPhone : fullEmail
    }

    /// Nhãn hiển thị trên thẻ tóm tắt liên hệ (vd "Số điện thoại đã đăng ký").
    var selectedFieldLabel: String {
        method == .phone ? "forgot.summary.phone.label".localized : "forgot.summary.email.label".localized
    }

    /// Chỉ phần số quốc gia gõ vào `ILPhoneField` (không gồm mã vùng) — tách ra từ `fullPhone` để
    /// tính độ hợp lệ, cùng quy ước với `ILLoginStateModel.nationalDigits`.
    private var nationalDigits: String {
        let dialDigits = selectedCountry.dialCode.filter(\.isNumber)
        let digitsOnly = fullPhone.filter(\.isNumber)
        let national = digitsOnly.hasPrefix(dialDigits) ? digitsOnly.dropFirst(dialDigits.count) : Substring(digitsOnly)
        // Bỏ số 0 đầu — cùng quy tắc đếm với `ILPhoneField` / `ILLoginStateModel.nationalDigits`.
        return String(national.drop(while: { $0 == "0" }))
    }

    /// `true` khi số đã đủ chữ số theo `selectedCountry` — bật dấu tick xanh trên `ILPhoneField`.
    var isPhoneValid: Bool {
        selectedCountry.isValidNationalDigitCount(nationalDigits.count)
    }

    var isSubmitEnabled: Bool {
        guard !isSubmitting else { return false }
        return method == .phone ? isPhoneValid : !fullEmail.isEmpty
    }

    static let initial = ILForgotPasswordStateModel()
}
