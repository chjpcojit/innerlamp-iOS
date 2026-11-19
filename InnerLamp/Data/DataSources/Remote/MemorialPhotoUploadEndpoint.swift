//
//  MemorialPhotoUploadEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `PUT /v1/memorials/{id}/photo` (contract §3.6), `multipart/form-data` with a
/// single part named `photo`. `Content-Type` must carry the boundary, so this endpoint declares
/// `nil` and the multipart uploader sets the header; the `Endpoint` default
/// (`application/json`) would make the server reject the body.
///
/// **Behind `MemorialPhotoEnabled` (default false)** until the route is deployed (D4).
nonisolated struct MemorialPhotoUploadEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials/" + id.pathSegmentEncoded + "/photo" }
    var method: HTTPMethod { .put }
}
