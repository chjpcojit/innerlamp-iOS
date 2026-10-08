//
//  DeityDetailEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/deities/{id}`. Returns `ILDeityDTO`; `404 DEITY_NOT_FOUND` for an unknown id.
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct DeityDetailEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/deities/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
