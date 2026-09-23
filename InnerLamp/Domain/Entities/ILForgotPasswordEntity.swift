//
//  ILForgotPasswordEntity.swift
//  InnerLamp
//

import Foundation

/// Cách nhận hướng dẫn đặt lại mật khẩu — khớp 2 thẻ lựa chọn "Số điện thoại"/"Email"
/// trong design handoff (`InnerLamp Prototype.dc.html`, `isForgot`, `resetWays`). Sống ở Domain
/// vì `ILForgotPasswordUseCase.sendResetInstructions(method:contact:)` cần kiểu này trong chữ ký
/// — không phải field UI-only nên không thuộc `ILForgotPasswordStateModel`.
enum ILForgotPasswordMethod: Equatable {
    case phone
    case email
}

/// Pure business entity for ForgotPassword — Domain layer only.
///
/// Holds only the fields with real business meaning: the registered contacts this feature reads
/// (to know where reset instructions can be sent). UI-only concerns (`*Error`, `isSubmitting`,
/// masked/display formatting) live on `ILForgotPasswordStateModel`
/// (`Presentation/Scenes/ForgotPassword/ILForgotPasswordStateModel.swift`) instead — see
/// `references/data_layer_boundaries.md`.
struct ILForgotPasswordEntity: Equatable {
    var fullPhone: String = ""
    var fullEmail: String = ""

    static let empty = ILForgotPasswordEntity()
}
