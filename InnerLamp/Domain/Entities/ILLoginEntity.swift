//
//  ILLoginEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for Login — Domain layer only.
///
/// Holds only the fields with real business meaning: the credentials this feature ultimately
/// sends to the server (email, password — contract 3.0.0, ADR-0003). UI-only concerns (`*Error`,
/// `isSubmitting`, display formatting) live on `ILLoginStateModel`
/// (`Presentation/Scenes/Login/ILLoginStateModel.swift`) instead — see
/// `references/data_layer_boundaries.md`.
struct ILLoginEntity: Equatable {
    /// EN: Trimmed email; the server lower-cases it, so the client sends it as typed.
    /// VI: Email đã cắt khoảng trắng; server tự chuyển chữ thường nên client gửi đúng như gõ.
    var email: String = ""
    var password: String = ""

    static let empty = ILLoginEntity()
}
