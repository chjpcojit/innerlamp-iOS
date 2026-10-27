//
//  ILSignUpEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for SignUp — Domain layer only.
///
/// Holds only the fields with real business meaning: the account data this feature ultimately
/// creates on the server (full name, optional dharma name, phone country + national digits, email,
/// password — contract 3.0.0, ADR-0003).
/// UI-only concerns (`*Error`, `isSubmitting`, `passwordStrength`, `isPasswordVisible`,
/// display formatting/hints) live on `ILSignUpStateModel`
/// (`Presentation/Scenes/SignUp/ILSignUpStateModel.swift`) instead — see
/// `references/data_layer_boundaries.md`.
struct ILSignUpEntity: Equatable {
    /// Bắt buộc — họ và tên thật của người đăng ký (`full_name` trên server).
    var fullName: String = ""
    /// EN: Optional dharma name; empty means "none" and is not sent.
    /// VI: Pháp danh tuỳ chọn; rỗng nghĩa là không có và không được gửi lên.
    var displayName: String = ""
    /// Tuỳ chọn — id chùa nơi xuất gia/thọ giới (`ordination_temple_id` trên server, lấy từ
    /// `GET /v1/temples/options`). `nil` nếu là cư sĩ chưa xuất gia hoặc chùa còn chờ duyệt.
    var ordinationTempleID: String?
    /// EN: ISO 3166 code of the picked country (`VN`, `US`, …) — `phone_country` on the server.
    /// VI: Mã ISO 3166 của quốc gia đã chọn (`VN`, `US`, …) — `phone_country` trên server.
    var phoneCountry: String = ""
    /// EN: National digits only, no dial code and no `+`; the server builds the E.164 form.
    /// VI: Chỉ phần số quốc gia, không mã vùng và không dấu `+`; server tự dựng dạng E.164.
    var phoneNumber: String = ""
    /// EN: Required — the sign-in identifier and where the verification code is sent.
    /// VI: Bắt buộc — định danh đăng nhập và là nơi nhận mã xác thực.
    var email: String = ""
    var password: String = ""

    static let empty = ILSignUpEntity()
}
