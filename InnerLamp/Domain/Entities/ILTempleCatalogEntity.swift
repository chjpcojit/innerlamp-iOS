//
//  ILTempleCatalogEntity.swift
//  InnerLamp
//

import Foundation

/// Kind of place of worship — the server's `type` enum. Open: an unknown value is kept as
/// `.other(raw)` instead of failing the whole page (backend contract: treat enum-like strings as
/// open).
nonisolated enum ILTempleType: Equatable {
    case chua
    case thienVien
    case daoTrang
    case tinhXa
    case thienXa
    case other(String)
}

/// Region of Vietnam — the server's `region` enum. Open, like `ILTempleType`.
nonisolated enum ILTempleRegion: Equatable {
    case north
    case central
    case south
    case other(String)
}

/// Heritage ranking — the server's `heritage_rank` enum. Declared in the server's sort order
/// (most prominent first). Open, like `ILTempleType`.
nonisolated enum ILTempleHeritageRank: Equatable {
    case worldHeritage
    case specialNationalRelic
    case nationalTouristArea
    case nationalRelic
    case scenicLandscape
    case provincialRelic
    case cityRelic
    case unranked
    case other(String)
}

nonisolated struct ILTempleLocationEntity: Equatable {
    let latitude: Double
    let longitude: Double
    let address: String
}

/// Yes/no facilities of a temple — the server's `amenities` object.
nonisolated struct ILTempleFacilitiesEntity: Equatable {
    let hasCarParking: Bool
    let hasMotorbikeParking: Bool
    let servesVegetarianMeals: Bool
    let hasSummerRetreat: Bool
}

/// Light temple row used by the "top" carousel and the "show all" list.
///
/// `thumbnailURL` / `imageURL` are the raw server strings (full URLs on the dev backend since
/// 2026-10-06, but `nil` for a temple without a photo); Presentation shows a placeholder when they
/// are missing or do not resolve. The host is the backend's LAN IP and changes per network, so
/// never rebuild these URLs — use the string the API returned.
nonisolated struct ILTempleSummaryEntity: Equatable, Identifiable {
    let id: String
    let name: String
    let type: ILTempleType
    let region: ILTempleRegion
    let thumbnailURL: String?
    let imageURL: String?
    /// Raw server value (e.g. "BẮC_TÔNG") — not an enum in the contract.
    let sect: String
    let heritageRank: ILTempleHeritageRank
    let establishedYear: Int
    let location: ILTempleLocationEntity
}

/// Full temple profile, fetched by id when a row is tapped.
nonisolated struct ILTempleDetailEntity: Equatable, Identifiable {
    let summary: ILTempleSummaryEntity
    /// Folk / alternative names — empty when none.
    let aliases: [String]
    let founder: String
    let currentAbbot: String
    /// Raw server string, e.g. "07:30 - 18:00".
    let operatingHours: String
    let facilities: ILTempleFacilitiesEntity
    /// "Giới thiệu" paragraph — empty when the server has no content yet. Editorial text, not
    /// an authoritative historical record.
    let introduction: String
    /// "Kiến trúc & di sản" paragraph — empty when missing.
    let architectureHeritage: String
    /// "Lưu ý khi viếng thăm" — one tip per element, blank ones dropped; empty when missing.
    let visitingNotes: [String]

    var id: String { summary.id }
}
