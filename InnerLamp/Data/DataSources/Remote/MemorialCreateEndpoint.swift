//
//  MemorialCreateEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/memorials` (201). Returns `ILMemorialDTO`; `409 MEMORIAL_LIMIT_REACHED`
/// once the user has 100 entries, `400 VALIDATION_ERROR` for a rejected field.
nonisolated struct MemorialCreateEndpoint: Endpoint {
    let request: ILMemorialRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/memorials" }
    var method: HTTPMethod { .post }

    /// Plain `JSONEncoder()` — the request DTO's explicit snake_case `CodingKeys` match the contract.
    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
