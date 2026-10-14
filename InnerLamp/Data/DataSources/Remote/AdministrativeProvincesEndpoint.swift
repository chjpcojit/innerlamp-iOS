//
//  AdministrativeProvincesEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/administrative-units/new/provinces`. Returns
/// `ILAdministrativeUnitListDTO<ILProvinceDTO>` (all 34 units, no paging).
///
/// Public endpoint: `requiresAuth == false` — the metadata routes take no `Authorization` header,
/// and mobile must not send `X-API-Key` (a wrong key is `401 INVALID_API_KEY`).
nonisolated struct AdministrativeProvincesEndpoint: Endpoint {
    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/administrative-units/new/provinces" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
