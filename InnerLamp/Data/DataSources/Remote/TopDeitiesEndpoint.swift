//
//  TopDeitiesEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/deities/top`. Returns `ILCatalogTopListDTO<ILDeitySummaryDTO>` (10 items, Buddhas first).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TopDeitiesEndpoint: Endpoint {

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/deities/top" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
