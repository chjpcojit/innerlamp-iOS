//
//  MemorialUpdateEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `PUT /v1/memorials/{id}` (replaces the whole entry). Returns `ILMemorialDTO`;
/// `404 MEMORIAL_NOT_FOUND` for an unknown id or one owned by another user.
nonisolated struct MemorialUpdateEndpoint: Endpoint {
    let id: String
    let request: ILMemorialRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .put }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
