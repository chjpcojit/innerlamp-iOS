//
//  ILSignUpOTPEntity.swift
//  InnerLamp
//

import Foundation

/// Metadata returned by `POST /v1/auth/register/request-otp` — Domain layer only.
///
/// Carried from SignUp to the OTP screen so its countdown and expiry copy use the server's real
/// values instead of hardcoded ones. `message` is the server's own human-readable note — the app
/// does not display it today (its copy is localized) but it is kept because the contract returns it.
struct ILSignUpOTPEntity: Equatable {
    var message: String = ""
    var expiresInSeconds: Int = 0
    var resendAfterSeconds: Int = 0

    static let empty = ILSignUpOTPEntity()
}
