//
//  ILLoginStateModel.swift
//  InnerLamp
//

import Foundation

/// Plain state model cho màn Đăng nhập — không UIKit, không business logic.
/// `ViewController` chỉ đọc field lỗi/trạng thái để hiển thị UI, không tự validate.
/// EN: Sign-in is by email since contract 3.0.0 (ADR-0003); there is no phone field or country picker.
/// VI: Đăng nhập bằng email từ contract 3.0.0 (ADR-0003); không còn ô số điện thoại hay bộ chọn quốc gia.
struct ILLoginStateModel {
    var email: String = ""
    var password: String = ""

    var emailError: String?
    var passwordError: String?

    /// Lỗi chung từ server/network (vd: sai tài khoản/mật khẩu) — hiển thị qua `showError`.
    var submitError: String?

    /// `true` trong lúc `ILLoginUseCase.login` đang chạy — dùng để chuyển `ILButton` sang `.loading`.
    var isSubmitting: Bool = false

    var hasValidationError: Bool {
        emailError != nil || passwordError != nil
    }

    var isSubmitEnabled: Bool {
        !isSubmitting
    }

    /// EN: The email sent to the server: surrounding whitespace removed (criterion 3).
    /// VI: Email gửi lên server: đã bỏ khoảng trắng đầu cuối (tiêu chí 3).
    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let initial = ILLoginStateModel()
}
