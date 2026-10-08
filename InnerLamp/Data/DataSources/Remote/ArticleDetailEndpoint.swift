//
//  ArticleDetailEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/articles/{id}`. Returns `ILArticleDetailDTO`;
/// `404 ARTICLE_NOT_FOUND` for an unknown id.
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct ArticleDetailEndpoint: Endpoint {
    let id: String

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/articles/" + id.pathSegmentEncoded }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
