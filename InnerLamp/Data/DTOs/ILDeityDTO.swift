//
//  ILDeityDTO.swift
//  InnerLamp
//

import Foundation

/// File format of the bundled "Buddhas & Bodhisattvas" catalog — Data layer.
///
/// Source: `Resources/Data/phat_botat.json` (copy of `Docs/Assert/Data/phat_botat.json`). The file
/// is a top-level array of `ILDeityDTO`, keyed in snake_case; the catalog is decoded with
/// `.convertFromSnakeCase`, so no `CodingKeys` are declared. A DTO never escapes upward past the
/// Data layer — `ILDeityMapper` converts it to `ILDeityEntity` first.
///
/// `imageUrl` is mapped into `ILDeityEntity.imageURL` (detail hero); `thumbnailUrl` is decoded only.
///
/// The same shape is the server's `DeityDetail` (`GET /v1/deities/{id}`), so the remote catalog
/// reuses this DTO. `Codable` (not just `Decodable`) so `ILDeityCatalogLocalDataSourceImpl` can
/// cache a fetched detail as an encoded payload; encoding and decoding that payload both use the
/// default key strategy, so the round-trip is lossless.
nonisolated struct ILDeityDTO: Codable {
    let id: String
    let type: ILDeityTypeDTO
    let nameVi: String
    let nameSanskrit: String
    let nameChinese: String
    let titleHonorific: String
    let thumbnailUrl: String?
    let imageUrl: String?
    let canonicalSource: String
    let coreVirtue: String
    let pureLand: String
    let lunarMemorialDays: [ILDeityMemorialDayDTO]
    let iconography: ILDeityIconographyDTO
    let biographySummary: String
    let greatVows: [String]
    let mantras: ILDeityMantraDTO
}

/// `type` column. An unknown value fails decoding rather than being silently defaulted
/// (the backend treats the enum as open: BUDDHA, BODHISATTVA, DEVA so far).
nonisolated enum ILDeityTypeDTO: String, Codable {
    case buddha = "BUDDHA"
    case bodhisattva = "BODHISATTVA"
    case deva = "DEVA"
}

nonisolated struct ILDeityMemorialDayDTO: Codable {
    let lunarDay: Int
    let lunarMonth: Int
    let eventName: String
}

nonisolated struct ILDeityIconographyDTO: Codable {
    let posture: String
    let mountOrThrone: String
    let sacredArtifacts: [String]
    let symbolicMeaning: String
}

nonisolated struct ILDeityMantraDTO: Codable {
    let shortMantraSanskrit: String
    let shortMantraSinoVietnamese: String
    let longDharaniName: String
    let dharaniPhoneticSnippet: String
}
