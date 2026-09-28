//
//  VerifyRegistrationOTPEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/auth/register/verify-otp`.
///
/// Naming: `<Action>Endpoint`, no `IL` prefix (the project's Endpoint exception); placement:
/// `Data/DataSources/Remote/`. Public endpoint — `requiresAuth == false` guarantees no
/// `Authorization` header regardless of Keychain state. `buildURLRequest()` already sets
/// Content-Type / Accept / X-Session-ID / X-Correlation-ID, so `headers` stays untouched.
nonisolated struct VerifyRegistrationOTPEndpoint: Endpoint {
    let request: ILOtpVerifyRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/auth/register/verify-otp" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    /// Plain `JSONEncoder()` — the request DTO's explicit snake_case `CodingKeys` make the body
    /// match the contract.
    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
