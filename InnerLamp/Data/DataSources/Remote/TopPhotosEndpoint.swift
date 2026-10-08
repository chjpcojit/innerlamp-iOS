//
//  TopPhotosEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/gallery/top`. Returns `ILCatalogTopListDTO<ILPhotosSummaryDTO>`
/// (10 items in the server's curated order, all four types; there is no parameter).
///
/// Public endpoint: `requiresAuth == false` — the gallery routes take no `Authorization` header.
nonisolated struct TopPhotosEndpoint: Endpoint {

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/gallery/top" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
