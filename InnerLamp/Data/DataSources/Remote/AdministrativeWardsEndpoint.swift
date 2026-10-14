//
//  AdministrativeWardsEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/administrative-units/new/provinces/{code}/wards[?q=...]`. Returns
/// `ILAdministrativeUnitListDTO<ILWardDTO>` (every ward of the province, no paging).
/// `404 ADMINISTRATIVE_UNIT_NOT_FOUND` for a code that is not in the 2-level system.
///
/// Public endpoint: `requiresAuth == false` (see `AdministrativeProvincesEndpoint`).
nonisolated struct AdministrativeWardsEndpoint: Endpoint {
    /// Server cap on `q`; a longer value is `400 INVALID_FILTER`.
    static let maxQueryLength = 100

    let provinceCode: String
    /// Free-text search over the ward full name. `nil`, empty or whitespace-only is left out of
    /// the request — the server answers `400 INVALID_FILTER` to an empty `q`.
    let query: String?

    init(provinceCode: String, query: String? = nil) {
        self.provinceCode = provinceCode
        self.query = query
    }

    var queryParameters: [String: String]? {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : ["q": String(trimmed.prefix(Self.maxQueryLength))]
    }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/administrative-units/new/provinces/" + provinceCode.pathSegmentEncoded + "/wards" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
