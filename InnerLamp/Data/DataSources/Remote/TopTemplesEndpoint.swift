//
//  TopTemplesEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/temples/top`. Returns `ILCatalogTopListDTO<ILTempleSummaryDTO>` (10 items).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TopTemplesEndpoint: Endpoint {

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/temples/top" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
