//
//  LoginEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/auth/login`.
///
/// Naming: `<Action>Endpoint`, no `IL` prefix — the project's `Endpoint` exception, matching
/// `RequestRegistrationOTPEndpoint`/`VerifyRegistrationOTPEndpoint`. Placement:
/// `Data/DataSources/Remote/`.
///
/// Public endpoint: `requiresAuth == false` guarantees no `Authorization` header is attached,
/// regardless of Keychain state. `buildURLRequest()` already applies `Content-Type`, `Accept`,
/// `X-Session-ID` and `X-Correlation-ID`, so `headers` is intentionally left untouched.
nonisolated struct LoginEndpoint: Endpoint {
    let request: ILLoginRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/auth/login" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    /// Encoded with a plain `JSONEncoder()` — no key strategy — so the request DTO's explicit
    /// snake_case `CodingKeys` are what make the body match the contract.
    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
