//
//  ILSignUpStateModel.swift
//  InnerLamp
//

import Foundation

/// Mức độ mạnh của mật khẩu — số segment tô màu trên `ILStrengthMeterView` (1...3) + nhãn.
/// Màu sắc hiển thị (ILColors) là chuyện của View, không đặt ở đây.
enum ILPasswordStrength: Equatable {
    case weak
    case fair
    case strong

    var filledSegments: Int {
        switch self {
        case .weak: return 1
        case .fair: return 2
        case .strong: return 3
        }
    }

    var label: String {
        switch self {
        case .weak: return "signup.password.weak".localized
        case .fair: return "signup.password.fair".localized
        case .strong: return "signup.password.strong".localized
        }
    }
}

/// Plain state model cho màn Đăng ký tài khoản — không UIKit, không business logic.
/// `ViewController` chỉ đọc field lỗi/trạng thái để hiển thị UI, không tự validate.
struct ILSignUpStateModel {
    var displayName: String = ""
    /// Vị trí hiện tại trong `ILSignUpUseCase.dharmaNameSuggestions` — field "Pháp danh" trong
    /// design handoff không có ô nhập tự do, chỉ có giá trị gợi ý + nút xoay vòng (`rollName`).
    var displayNameSuggestionIndex: Int = 0

    /// Tuỳ chọn — nơi xuất gia/thọ giới (`ordination_place`). Nhập tự do, không validate, không
    /// chặn submit (rỗng = không gửi).
    var ordinationPlace: String = ""

    /// Số quốc gia đang chọn cho mã vùng (`ccIdx`/`toggleCC` trong design handoff) — mặc định
    /// Việt Nam.
    var selectedCountry: ILCountry = .default
    /// Chỉ phần số quốc gia người dùng gõ, KHÔNG gồm mã vùng (`nationalDigits()` trong design
    /// handoff) — mã vùng hiển thị riêng ở bộ chọn, ghép lại khi submit/hiển thị OTP.
    var phoneNumber: String = ""
    /// Bắt buộc — để nhận biên nhận cúng dường. Rỗng/sai định dạng đều chặn submit
    /// (`ILSignUpUseCase.validateEmail`); trong lúc gõ chỉ đổi viền live qua `isEmailFormatValid`.
    var email: String = ""
    var password: String = ""

    var displayNameError: String?
    var phoneNumberError: String?
    var emailError: String?
    var passwordError: String?

    /// `nil` khi password rỗng — `ILStrengthMeterView` ẩn nhãn/để bar rỗng.
    var passwordStrength: ILPasswordStrength?

    var isPasswordVisible: Bool = false
    var didAcceptTerms: Bool = false

    /// Lỗi chung từ server/network (vd: số điện thoại đã được đăng ký) — hiển thị qua `showError`.
    var submitError: String?

    /// `true` trong lúc `ILSignUpUseCase.sendVerificationCode` đang chạy — dùng để chuyển
    /// `ILButton` sang `.loading`.
    var isSubmitting: Bool = false

    var hasValidationError: Bool {
        displayNameError != nil || phoneNumberError != nil || emailError != nil || passwordError != nil
    }

    /// Chỉ giữ chữ số, bỏ số 0 đầu (khớp `nationalDigits()` trong design handoff — người dùng có
    /// thể gõ `0912...` hoặc `912...`, cả hai đều tính là cùng một số).
    var nationalDigits: String {
        let digitsOnly = phoneNumber.filter(\.isNumber)
        var trimmed = Substring(digitsOnly)
        while trimmed.first == "0" { trimmed.removeFirst() }
        return String(trimmed)
    }

    /// Hợp lệ khi số chữ số nằm trong `selectedCountry.nationalDigitRange` (vd VN: 9...9) —
    /// `ILPhoneField` đã chặn gõ vượt cận trên.
    var isPhoneValid: Bool {
        selectedCountry.isValidNationalDigitCount(nationalDigits.count)
    }

    /// Số điện thoại đầy đủ dạng quốc tế, số cách nhau từng nhóm 3 chữ số — dùng để gửi OTP và
    /// hiển thị ở màn OTP (`phoneE164()` trong design handoff).
    var phoneE164: String {
        var groups: [String] = []
        var remaining = Substring(nationalDigits)
        while !remaining.isEmpty {
            groups.append(String(remaining.prefix(3)))
            remaining.removeFirst(min(3, remaining.count))
        }
        return ([selectedCountry.dialCode] + groups).joined(separator: " ")
    }

    /// Gợi ý định dạng khi chưa đủ số, hoặc xác nhận số sẽ nhận mã khi đã đủ — khớp `phoneHint`
    /// trong design handoff.
    var phoneHint: String {
        isPhoneValid
            ? String(format: "signup.field.phone.hint.willSend".localized, phoneE164)
            : String(format: "signup.field.phone.hint.format".localized, selectedCountry.dialCode)
    }

    /// `true` khi đã gõ gì đó vào ô email — dùng để chỉ tô đỏ/xanh live khi đã có gõ; email rỗng
    /// vẫn bị chặn ở lúc submit qua `emailError` (trường bắt buộc).
    var hasEmailValue: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Định dạng email hợp lệ — chỉ có ý nghĩa khi `hasEmailValue == true` (khớp `emailValid()`
    /// trong design handoff).
    var isEmailFormatValid: Bool {
        ILEmailValidator.isValid(email)
    }

    /// Nút CTA chỉ bật khi đã tick điều khoản — khớp hành vi trong design handoff
    /// (`InnerLamp Prototype.dc.html`, `signupBg`/`signupFg` phụ thuộc `s.terms`).
    var isSubmitEnabled: Bool {
        didAcceptTerms && !isSubmitting
    }

    static let initial = ILSignUpStateModel()
}
