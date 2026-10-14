//
//  ILSignUpEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for SignUp — Domain layer only.
///
/// Holds only the fields with real business meaning: the account data this feature ultimately
/// creates on the server (display name / dharma name, phone number in E.164 form, password).
/// UI-only concerns (`*Error`, `isSubmitting`, `passwordStrength`, `isPasswordVisible`,
/// display formatting/hints) live on `ILSignUpStateModel`
/// (`Presentation/Scenes/SignUp/ILSignUpStateModel.swift`) instead — see
/// `references/data_layer_boundaries.md`.
struct ILSignUpEntity: Equatable {
    /// Bắt buộc — họ và tên thật của người đăng ký (`full_name` trên server).
    var fullName: String = ""
    var displayName: String = ""
    /// Tuỳ chọn — id chùa nơi xuất gia/thọ giới (`ordination_temple_id` trên server, lấy từ
    /// `GET /v1/temples/options`). `nil` nếu là cư sĩ chưa xuất gia hoặc chùa còn chờ duyệt.
    var ordinationTempleID: String?
    var phoneNumber: String = ""
    /// Bắt buộc — dùng để nhận biên nhận cúng dường, không phải định danh đăng nhập.
    var email: String = ""
    var password: String = ""

    static let empty = ILSignUpEntity()
}
