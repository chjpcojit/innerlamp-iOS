//
//  ILOtpDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format for the OTP feature's two calls — Data layer. Contract:
/// innerlamp-be `docs/specs/api/openapi.yaml` (`VerifyOtpRequest` / `AuthEnvelope`,
/// `ResendOtpRequest` / `ResendOtpEnvelope`).
///
/// Requests declare explicit snake_case `CodingKeys` (the shared `JSONEncoder` has no key
/// strategy); responses declare none and rely on the decoder's `.convertFromSnakeCase`. One type
/// per wire shape.

nonisolated struct ILOtpVerifyRequestDTO: Encodable {
    /// EN: The email used on `register/request-otp` (contract 3.0.0).
    /// VI: Email đã dùng ở `register/request-otp` (contract 3.0.0).
    let email: String
    let otpCode: String

    enum CodingKeys: String, CodingKey {
        case email
        case otpCode = "otp_code"
    }
}

nonisolated struct ILOtpVerifyResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: ILOtpUserDTO
}

/// The `user` object carried by a successful `verify-otp`.
///
/// Only the fields the app actually stores are modelled; the server's `created_at` is omitted
/// because `ILUserEntity` / the Core Data store do not model it (see `Docs/Specs/Onboarding/`).
nonisolated struct ILOtpUserDTO: Decodable {
    let id: Int64
    let email: String
    let phoneNumber: String
    let dharmaName: String?
    /// EN: `ordination_temple_id` in `AuthResult.user`; absent when the user picked no temple.
    /// VI: `ordination_temple_id` trong `AuthResult.user`; vắng khi người dùng chưa chọn chùa.
    let ordinationTempleId: String?
}

/// EN: Body of `POST /v1/auth/register/resend-otp` — the email only; `purpose` is rejected as an unknown field.
/// VI: Body của `POST /v1/auth/register/resend-otp` — chỉ có email; `purpose` bị từ chối vì là field lạ.
nonisolated struct ILOtpResendRequestDTO: Encodable {
    let email: String

    enum CodingKeys: String, CodingKey {
        case email
    }
}

nonisolated struct ILOtpResendResponseDTO: Decodable {
    let message: String
    let expiresInSeconds: Int
    let resendAfterSeconds: Int
}
