//
//  TemplesPageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/temples?page=N`. Returns `ILCatalogPageDTO<ILTempleSummaryDTO>` (fixed page size 20).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TemplesPageEndpoint: Endpoint {
    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int

    var queryParameters: [String: String]? { ["page": String(page)] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/temples" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
