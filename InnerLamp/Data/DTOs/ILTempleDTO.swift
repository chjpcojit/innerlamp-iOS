//
//  ILTempleDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of the temple catalog — Data layer. Contract: `docs/specs/features/temple/api-contract.md`
/// in the backend repo (`TempleSummary` / `TempleDetail`).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. Enum-like fields
/// (`type`, `region`, `heritageRank`) stay `String` here so an unknown server value never fails the
/// page — `ILTempleMapper` maps them to open Domain enums. A DTO never escapes the Data layer.
nonisolated struct ILTempleSummaryDTO: Codable, Sendable {
    let id: String
    let name: String
    let type: String
    let region: String
    let thumbnailUrl: String?
    let imageUrl: String?
    let sect: String
    let heritageRank: String
    let establishedYear: Int
    let location: ILTempleLocationDTO
}

nonisolated struct ILTempleLocationDTO: Codable, Sendable {
    let lat: Double
    let lng: Double
    let address: String
}

/// `TempleDetail` = every `TempleSummary` field plus the profile fields below. Declared flat
/// because the server sends one flat object.
///
/// `Codable` so the local data source can cache the detail-only fields as an encoded payload.
nonisolated struct ILTempleDetailDTO: Codable, Sendable {
    let id: String
    let name: String
    let type: String
    let region: String
    let thumbnailUrl: String?
    let imageUrl: String?
    let sect: String
    let heritageRank: String
    let establishedYear: Int
    let location: ILTempleLocationDTO
    /// Never `null` per contract; may be empty.
    let aliases: [String]
    let founder: String
    let currentAbbot: String
    let operatingHours: String
    let amenities: ILTempleAmenitiesDTO
    /// Contract v1.1 editorial content — never `null` on the wire (`""` / `[]` when missing).
    /// Optional here only so a detail payload cached before v1.1 (without these keys) still
    /// decodes as an offline fallback; `ILTempleMapper` maps `nil` to empty.
    let introduction: String?
    let architectureHeritage: String?
    let visitingNotes: [String]?

    var summary: ILTempleSummaryDTO {
        ILTempleSummaryDTO(
            id: id, name: name, type: type, region: region,
            thumbnailUrl: thumbnailUrl, imageUrl: imageUrl, sect: sect,
            heritageRank: heritageRank, establishedYear: establishedYear, location: location
        )
    }
}

nonisolated struct ILTempleAmenitiesDTO: Codable, Sendable {
    let parkingCar: Bool
    let parkingMotorcycle: Bool
    let vegetarianMeals: Bool
    let summerRetreat: Bool
}
