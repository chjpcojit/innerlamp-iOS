//
//  TopArticlesEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/articles/top`. Returns `ILCatalogTopListDTO<ILArticleSummaryDTO>`
/// (5 items in the server's curated order; there is no `limit` parameter).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TopArticlesEndpoint: Endpoint {

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/articles/top" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
