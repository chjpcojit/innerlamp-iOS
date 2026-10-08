//
//  MemorialsListEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/memorials`. Returns `ILMemorialListDTO` (the signed-in user's whole
/// book, at most 100 entries, newest first). Requires the access token.
nonisolated struct MemorialsListEndpoint: Endpoint {
    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials" }
    var method: HTTPMethod { .get }
}
