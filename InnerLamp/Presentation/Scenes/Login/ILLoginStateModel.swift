//
//  ILLoginStateModel.swift
//  InnerLamp
//

import Foundation

/// Plain state model cho màn Đăng nhập — không UIKit, không business logic.
/// `ViewController` chỉ đọc field lỗi/trạng thái để hiển thị UI, không tự validate.
/// Đăng nhập chỉ bằng số điện thoại (`+84`) — design handoff không có email
/// (xem README `login` — "chỉ số điện thoại — không có email").
struct ILLoginStateModel {
    var selectedCountry: ILCountry = .default
    /// Chỉ phần số quốc gia người dùng gõ vào `ILPhoneField`, KHÔNG gồm mã vùng.
    var phone: String = ""
    var password: String = ""

    var phoneError: String?
    var passwordError: String?

    /// Lỗi chung từ server/network (vd: sai tài khoản/mật khẩu) — hiển thị qua `showError`.
    var submitError: String?

    /// `true` trong lúc `ILLoginUseCase.login` đang chạy — dùng để chuyển `ILButton` sang `.loading`.
    var isSubmitting: Bool = false

    var hasValidationError: Bool {
        phoneError != nil || passwordError != nil
    }

    var isSubmitEnabled: Bool {
        !isSubmitting
    }

    /// Chỉ giữ chữ số, bỏ số 0 đầu — cùng quy tắc với `ILSignUpStateModel.nationalDigits`
    /// (người dùng gõ `0912…` hay `912…` đều tính là cùng một số).
    var nationalDigits: String {
        let digitsOnly = phone.filter(\.isNumber)
        var trimmed = Substring(digitsOnly)
        while trimmed.first == "0" { trimmed.removeFirst() }
        return String(trimmed)
    }

    var isPhoneValid: Bool {
        selectedCountry.isValidNationalDigitCount(nationalDigits.count)
    }

    /// Số điện thoại đầy đủ dạng quốc tế, nhóm 3 chữ số cách nhau bằng khoảng trắng — CÙNG định
    /// dạng với `ILSignUpStateModel.phoneE164` để so khớp đúng số đã lưu lúc đăng ký.
    var phoneE164: String {
        var groups: [String] = []
        var remaining = Substring(nationalDigits)
        while !remaining.isEmpty {
            groups.append(String(remaining.prefix(3)))
            remaining.removeFirst(min(3, remaining.count))
        }
        return ([selectedCountry.dialCode] + groups).joined(separator: " ")
    }

    static let initial = ILLoginStateModel()
}
