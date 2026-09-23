//
//  ILLoginEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for Login — Domain layer only.
///
/// Holds only the fields with real business meaning: the credentials this feature ultimately
/// sends to the server (phone number in E.164 form, password). UI-only concerns (`*Error`,
/// `isSubmitting`, display formatting) live on `ILLoginStateModel`
/// (`Presentation/Scenes/Login/ILLoginStateModel.swift`) instead — see
/// `references/data_layer_boundaries.md`.
struct ILLoginEntity: Equatable {
    var phone: String = ""
    var password: String = ""

    static let empty = ILLoginEntity()
}
