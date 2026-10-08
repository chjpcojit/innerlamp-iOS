//
//  SutraDetailEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/sutras/{id}`. Returns `ILSutraDTO` (with translation sources and
/// `sections`); `404 SUTRA_NOT_FOUND` for an unknown id.
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct SutraDetailEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/sutras/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
