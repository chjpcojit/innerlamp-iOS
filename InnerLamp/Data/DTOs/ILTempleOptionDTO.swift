//
//  ILTempleOptionDTO.swift
//  InnerLamp
//

import Foundation

/// One row of `GET /v1/temples/options` — Data layer. The page wrapper is the shared
/// `ILCatalogPageDTO<ILTempleOptionDTO>`.
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`.
nonisolated struct ILTempleOptionDTO: Decodable, Sendable {
    /// Stable string id such as `"temple_north_011"` — the same id other endpoints take.
    let id: String
    let name: String
    let province: String
    /// `null` for a temple the backend has not re-seeded with a province code yet.
    let provinceCode: String?
}

/// Body of `POST /v1/temple-suggestions`. Explicit snake_case `CodingKeys` because the shared
/// `JSONEncoder` has no key strategy (see `ILSignUpRequestOTPRequestDTO`).
nonisolated struct ILTempleSuggestionRequestDTO: Encodable, Equatable {
    let name: String
    let provinceCode: String
    let wardCode: String
    let address: String

    enum CodingKeys: String, CodingKey {
        case name
        case provinceCode = "province_code"
        case wardCode = "ward_code"
        case address
    }
}

/// `data` of a successful `POST /v1/temple-suggestions` (`201`): `{ id, status: "pending" }`.
nonisolated struct ILTempleSuggestionResponseDTO: Decodable, Sendable {
    let id: String
    let status: String
}
