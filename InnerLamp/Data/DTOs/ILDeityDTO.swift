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
/// `thumbnailUrl` / `imageUrl` are decoded but not mapped: `ILDeityEntity` does not model images yet.
nonisolated struct ILDeityDTO: Decodable {
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

/// `type` column. An unknown value fails decoding rather than being silently defaulted.
nonisolated enum ILDeityTypeDTO: String, Decodable {
    case buddha = "BUDDHA"
    case bodhisattva = "BODHISATTVA"
}

nonisolated struct ILDeityMemorialDayDTO: Decodable {
    let lunarDay: Int
    let lunarMonth: Int
    let eventName: String
}

nonisolated struct ILDeityIconographyDTO: Decodable {
    let posture: String
    let mountOrThrone: String
    let sacredArtifacts: [String]
    let symbolicMeaning: String
}

nonisolated struct ILDeityMantraDTO: Decodable {
    let shortMantraSanskrit: String
    let shortMantraSinoVietnamese: String
    let longDharaniName: String
    let dharaniPhoneticSnippet: String
}
