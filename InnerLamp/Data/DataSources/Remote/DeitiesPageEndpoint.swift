//
//  DeitiesPageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/deities?page=N`. Returns `ILCatalogPageDTO<ILDeitySummaryDTO>` (page size set by the server, Buddhas then Bodhisattvas by `sort_order`; no type filter).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct DeitiesPageEndpoint: Endpoint {
    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int

    var queryParameters: [String: String]? { ["page": String(page)] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/deities" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
