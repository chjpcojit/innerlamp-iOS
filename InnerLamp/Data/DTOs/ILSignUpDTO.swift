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
/// Contract: innerlamp-be `docs/specs/api/openapi.yaml` `RequestOtpRequest` /
/// `OtpSentEnvelope` — `POST /v1/auth/register/request-otp`.
nonisolated struct ILSignUpRequestOTPRequestDTO: Encodable {
    let fullName: String
    let dharmaName: String
    /// Optional — id from `GET /v1/temples/options`. `nil` is omitted from the body (the server
    /// reads an absent field as "no temple"); an unknown id is `400 INVALID_TEMPLE`. The old
    /// `ordination_place` field is rejected by the server (strict body decoding).
    let ordinationTempleId: String?
    let phoneNumber: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dharmaName = "dharma_name"
        case ordinationTempleId = "ordination_temple_id"
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
