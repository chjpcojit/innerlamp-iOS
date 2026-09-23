//
//  ILSignUpRepository.swift
//  InnerLamp
//

import Foundation

/// Domain-layer contract for SignUp's server call.
///
/// Entity in, `ILSignUpOTPEntity` out — the confirmed `POST /v1/auth/register/request-otp` success
/// response carries the OTP-delivery metadata (`message`, `expires_in_seconds`,
/// `resend_after_seconds`) that the OTP screen's countdown needs. See `Docs/Specs/SignUp/design.md`.
///
/// No `ILSignUpDTO` may appear in this file or anywhere else under `Domain/` — the wire format is
/// a Data-layer detail that stops at this boundary. No `ILSignUpStateModel` either.
///
/// Throws `ILSignUpError` — never a raw `NetworkError`, which is a Core transport detail the layers
/// above do not know about.
nonisolated protocol ILSignUpRepository {

    /// Submits the registration payload and asks the server to send a verification code by SMS.
    ///
    /// On the server this only writes to `pending_registration`; the account is created later by
    /// the follow-on `verify-otp` call, which belongs to the OTP feature.
    func requestRegistrationOTP(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity
}
