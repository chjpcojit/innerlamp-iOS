//
//  ILLoginDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format for Login's server call — Data layer.
///
/// Request and response are split on purpose: the shared `JSONDecoder` uses `.convertFromSnakeCase`
/// but the `JSONEncoder` has no key strategy, so the two sides cannot share one type. The request
/// declares explicit snake_case `CodingKeys`; the response declares none and relies on the decoder.
/// See `.claude/skills/data-builder/references/data_layer_architecture.md` §5.
///
/// Contract: innerlamp-be `docs/specs/api/openapi.yaml` `LoginRequest` / `AuthEnvelope.data`
/// (= `AuthResult`) — `POST /v1/auth/login`.
nonisolated struct ILLoginRequestDTO: Encodable {
    /// EN: Sign-in identifier since contract 3.0.0 (ADR-0003); the server rejects `phone_number` as an unknown field.
    /// VI: Định danh đăng nhập từ contract 3.0.0 (ADR-0003); server từ chối `phone_number` vì là field lạ.
    let email: String
    let password: String
    let device: ILLoginDeviceDTO

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case device
    }
}

/// `device` object on `LoginRequest` — what the client says about itself. Derived from
/// `UIDevice`/`Bundle` at the Data boundary (see `Docs/Specs/Login/design.md` "Login API contract
/// (confirmed)" gap #1) so `ILLoginEntity` stays free of platform details. The server adds
/// `ip_address`/`user_agent` itself; sending them here would be rejected as an unknown field.
nonisolated struct ILLoginDeviceDTO: Encodable {
    let platform: String
    let deviceModel: String
    let osVersion: String?
    let appVersion: String?
    let deviceName: String?

    enum CodingKeys: String, CodingKey {
        case platform
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case deviceName = "device_name"
    }
}

/// `data` of a successful `POST /v1/auth/login` — `VerifyOTPData` = `{ access_token, refresh_token,
/// user }`, the same shape the backend returns for registration (see `ILAuthSessionEntity`'s doc
/// comment).
nonisolated struct ILLoginResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: ILLoginUserDTO
}

/// The `user` object carried by a successful login. Only the fields `ILUserEntity` models are
/// declared here — the server's `created_at` is omitted, same precedent as `ILOtpUserDTO`.
nonisolated struct ILLoginUserDTO: Decodable {
    let id: Int64
    let email: String
    let phoneNumber: String
    let dharmaName: String?
    /// EN: `ordination_temple_id` in `AuthResult.user`; absent when the user picked no temple.
    /// VI: `ordination_temple_id` trong `AuthResult.user`; vắng khi người dùng chưa chọn chùa.
    let ordinationTempleId: String?
}
