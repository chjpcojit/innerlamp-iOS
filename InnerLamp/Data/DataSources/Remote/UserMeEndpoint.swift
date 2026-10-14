//
//  UserMeEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/users/me`. Returns `ILUserMeDTO` — the signed-in user's account
/// profile. Requires the access token (owner comes from the token claim; no `X-API-Key`).
///
/// The response is `Cache-Control: no-store` and carries PII, so nothing here is cached on disk.
nonisolated struct UserMeEndpoint: Endpoint {
    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/users/me" }
    var method: HTTPMethod { .get }
}
