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
    /// EN: Optional since contract 3.0.0 — `nil` is omitted from the body (the server stores "no dharma name").
    /// VI: Tuỳ chọn từ contract 3.0.0 — `nil` không có trong body (server lưu là không có pháp danh).
    let dharmaName: String?
    /// Optional — id from `GET /v1/temples/options`. `nil` is omitted from the body (the server
    /// reads an absent field as "no temple"); an unknown id is `400 INVALID_TEMPLE`. The old
    /// `ordination_place` field is rejected by the server (strict body decoding).
    let ordinationTempleId: String?
    /// EN: ISO 3166 code of the picked country (`VN`, `US`, …); the server rebuilds E.164 from it.
    /// VI: Mã ISO 3166 của quốc gia đã chọn (`VN`, `US`, …); server tự dựng lại dạng E.164.
    let phoneCountry: String
    /// EN: The national digits as typed, without the dial code or `+` — never rebuilt into E.164 on the client.
    /// VI: Các chữ số người dùng gõ, không kèm mã quốc gia hay dấu `+` — client không tự dựng E.164.
    let phoneNumber: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dharmaName = "dharma_name"
        case ordinationTempleId = "ordination_temple_id"
        case phoneCountry = "phone_country"
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
