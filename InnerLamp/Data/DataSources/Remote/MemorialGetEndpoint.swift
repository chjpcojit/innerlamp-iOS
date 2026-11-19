//
//  MemorialGetEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/memorials/{id}` (contract §3.3). `404 MEMORIAL_NOT_FOUND` covers a
/// missing id and another user's id with the same body; the client must not distinguish them.
nonisolated struct MemorialGetEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .get }
}
