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
    var displayName: String = ""
    /// Tuỳ chọn — nơi xuất gia/thọ giới (`ordination_place` trên server), để trống nếu là cư sĩ.
    var ordinationPlace: String = ""
    var phoneNumber: String = ""
    /// Bắt buộc — dùng để nhận biên nhận cúng dường, không phải định danh đăng nhập.
    var email: String = ""
    var password: String = ""

    static let empty = ILSignUpEntity()
}
