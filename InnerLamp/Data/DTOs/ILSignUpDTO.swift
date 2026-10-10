//
//  ILSignUpDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format for SignUp's registration call — Data layer.
///
/// Request and response are split on purpose: the shared `JSONDecoder` uses `.convertFromSnakeCase`
/// but the `JSONEncoder` has no key strategy, so the two sides cannot share one type. The request
/// declares explicit snake_case `CodingKeys`; the response declares none and relies on the decoder.
/// See `.claude/skills/data-builder/references/data_layer_architecture.md` §5.
///
/// Contract: `Docs/Specs/API/openapi.yaml` v3.9 `RequestOTPRequest` /
/// `RequestOTPData` — `POST /v1/auth/register/request-otp`.
nonisolated struct ILSignUpRequestOTPRequestDTO: Encodable {
    let dharmaName: String
    /// Optional — sent as an empty string when the user left the field blank.
    let ordinationPlace: String
    let phoneNumber: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case dharmaName = "dharma_name"
        case ordinationPlace = "ordination_place"
        case phoneNumber = "phone_number"
        case email
        case password
    }
}

/// `data` of a successful `POST /v1/auth/register/request-otp` —
/// `{ message, expires_in_seconds, resend_after_seconds }`.
///
/// No `CodingKeys`: the shared decoder's `.convertFromSnakeCase` maps the server's snake_case keys
/// to these camelCase properties.
nonisolated struct ILSignUpRequestOTPResponseDTO: Decodable {
    let message: String
    let expiresInSeconds: Int
    let resendAfterSeconds: Int
}
