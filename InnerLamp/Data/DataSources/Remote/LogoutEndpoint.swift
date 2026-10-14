//
//  LogoutEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/auth/logout`. Revokes the session the access token belongs to (the
/// session id comes from the token, never the body). The response is `{"success":true}` with no
/// `data`, so call the `request(endpoint:)` overload that returns nothing. Idempotent: an
/// already-revoked session still answers 200.
nonisolated struct LogoutEndpoint: Endpoint {
    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/auth/logout" }
    var method: HTTPMethod { .post }
}
