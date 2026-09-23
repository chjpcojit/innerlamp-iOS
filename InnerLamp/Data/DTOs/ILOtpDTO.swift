//
//  ILOtpDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format for the OTP feature's two calls — Data layer. Contract:
/// `Docs/Specs/API/openapi.yaml` v3.9 (`VerifyOTPRequest` / `VerifyOTPData`,
/// `ResendOTPRequest` / `ResendOTPData`).
///
/// Requests declare explicit snake_case `CodingKeys` (the shared `JSONEncoder` has no key
/// strategy); responses declare none and rely on the decoder's `.convertFromSnakeCase`. One type
/// per wire shape.

nonisolated struct ILOtpVerifyRequestDTO: Encodable {
    let phoneNumber: String
    let otpCode: String

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
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
/// because `ILUserEntity` / the Core Data store do not model it (see `Docs/Specs/Otp/`).
nonisolated struct ILOtpUserDTO: Decodable {
    let id: Int64
    let email: String
    let phoneNumber: String
    let dharmaName: String?
    let ordinationPlace: String?
}

nonisolated struct ILOtpResendRequestDTO: Encodable {
    let phoneNumber: String
    let purpose: String

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case purpose
    }
}

nonisolated struct ILOtpResendResponseDTO: Decodable {
    let message: String
    let expiresInSeconds: Int
    let resendAfterSeconds: Int
}
