//
//  ILAdministrativeUnitDTO.swift
//  InnerLamp
//

import Foundation

/// `data` of the administrative-unit list endpoints: `{ "items": [...] }`.
nonisolated struct ILAdministrativeUnitListDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
}

/// One row of `GET /v1/administrative-units/new/provinces` — Data layer.
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`.
nonisolated struct ILProvinceDTO: Decodable, Sendable {
    let code: String
    let name: String
    let fullName: String
    /// `"province"` | `"city"`.
    let type: String
}

/// One row of `GET /v1/administrative-units/new/provinces/{code}/wards`.
nonisolated struct ILWardDTO: Decodable, Sendable {
    let code: String
    let name: String
    let fullName: String
    /// `"ward"` | `"commune"` | `"special_zone"`.
    let type: String
    let provinceCode: String
}
