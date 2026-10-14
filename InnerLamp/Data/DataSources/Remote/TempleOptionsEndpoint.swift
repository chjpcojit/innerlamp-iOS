//
//  TempleOptionsEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/temples/options?page=N[&q=...]`. Returns
/// `ILCatalogPageDTO<ILTempleOptionDTO>` (fixed page size 100).
///
/// A light list for pickers: `id` / `name` / `province` / `province_code` only (no address, no
/// image). The shared card list `GET /v1/temples` has no search; this one does.
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct TempleOptionsEndpoint: Endpoint {
    /// Server cap on `q`; a longer value is `400 INVALID_FILTER`.
    static let maxQueryLength = 100

    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int
    /// Free-text search over the temple `name` (server side: contains, case- and
    /// diacritic-insensitive). `nil`, empty or whitespace-only is left out of the request — the
    /// server answers `400 INVALID_FILTER` to an empty `q`.
    let query: String?

    init(page: Int, query: String? = nil) {
        self.page = page
        self.query = query
    }

    var queryParameters: [String: String]? {
        var parameters = ["page": String(page)]
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            parameters["q"] = String(trimmed.prefix(Self.maxQueryLength))
        }
        return parameters
    }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/temples/options" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
