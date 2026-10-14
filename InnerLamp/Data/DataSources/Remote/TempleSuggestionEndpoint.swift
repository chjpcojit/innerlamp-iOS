//
//  TempleSuggestionEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/temple-suggestions`. Proposes a temple that is missing from the
/// catalog; the server stores it as `pending` until a backoffice admin approves it, so the answer
/// carries a suggestion id, **not** a temple id (`201 { id, status: "pending" }`).
///
/// Public endpoint: `requiresAuth == false`, no token. No `X-API-Key` — that header is for the web
/// client only and a wrong value is `401 INVALID_API_KEY`. The server limits it to 5 requests per
/// IP per hour (`429 RATE_LIMITED`).
nonisolated struct TempleSuggestionEndpoint: Endpoint {
    let request: ILTempleSuggestionRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/temple-suggestions" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    /// Encoded with a plain `JSONEncoder()` — the request DTO's explicit snake_case `CodingKeys`
    /// make the body match the contract.
    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
