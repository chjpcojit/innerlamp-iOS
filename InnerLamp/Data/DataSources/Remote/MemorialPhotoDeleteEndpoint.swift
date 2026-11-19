//
//  MemorialPhotoDeleteEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `DELETE /v1/memorials/{id}/photo` (contract §3.7). An entry without a photo
/// still returns 200 with `photo_url: null`.
///
/// **Behind `MemorialPhotoEnabled` (default false)** until the route is deployed (D4).
nonisolated struct MemorialPhotoDeleteEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials/" + id.pathSegmentEncoded + "/photo" }
    var method: HTTPMethod { .delete }
}
