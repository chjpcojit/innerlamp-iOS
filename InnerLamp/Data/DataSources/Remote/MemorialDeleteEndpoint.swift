//
//  MemorialDeleteEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `DELETE /v1/memorials/{id}` (hard delete). The response is `{"success":true}`
/// with no `data`, so call the `request(endpoint:)` overload that returns nothing. A second delete
/// of the same id is `404 MEMORIAL_NOT_FOUND`.
nonisolated struct MemorialDeleteEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .delete }
}
