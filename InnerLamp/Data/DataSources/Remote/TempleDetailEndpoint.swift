//
//  TempleDetailEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/temples/{id}`. Returns `ILTempleDetailDTO`; `404 TEMPLE_NOT_FOUND` for an unknown id.
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TempleDetailEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/temples/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
