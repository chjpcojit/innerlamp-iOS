//
//  ArticlesPageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/articles?page=N`. Returns `ILCatalogPageDTO<ILArticleSummaryDTO>`
/// (fixed page size 10; no size / filter / search parameters).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct ArticlesPageEndpoint: Endpoint {
    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int

    var queryParameters: [String: String]? { ["page": String(page)] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/articles" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
