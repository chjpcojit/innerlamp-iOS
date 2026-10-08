//
//  ILSutraDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of the sutra catalog (`GET /v1/sutras`, `GET /v1/sutras/{id}`) — Data layer.
/// Contract: BE `docs/specs/api/openapi.yaml` (`/v1/sutras*`), confirmed by the backend team,
/// 2026-10-07.
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. List and detail share
/// one DTO — the detail only adds fields (`review_status`, per-translation `source_*`, `note`,
/// `sections`), declared optional here. The list wrapper reuses `ILCatalogPageDTO`. A DTO never
/// escapes the Data layer.
nonisolated struct ILSutraDTO: Decodable, Sendable {
    let id: String
    /// `THERAVADA` | `MAHAYANA` | `VAJRAYANA` — decoded as text so a new server value never fails
    /// the whole page.
    let tradition: String?
    /// `SUTRA` | `VERSE` | `DHARANI`.
    let kind: String?
    let collection: String?
    let reference: String?
    /// Title per language code (`vi`, `en`, `pli`, ...).
    let titles: [String: String]
    let dailyChant: Bool
    /// `CAU_AN`, `CAU_SIEU`, ... — unknown values are dropped by the mapper.
    let purposes: [String]
    /// `null` when the server has no duration estimate.
    let durationMinutes: Int?
    let translations: [ILSutraTranslationDTO]
    /// Empty string when the sutra has no audio; optional so an older server never fails the page.
    let audioUrl: String?
}

nonisolated struct ILSutraTranslationDTO: Decodable, Sendable {
    /// Request key for `/v1/sutras/{id}/lines?translation=`, e.g. `vi-translation`.
    let key: String
    let lang: String
    let translator: String?
    let license: String?
    let lineCount: Int
    // Detail only.
    let sourceName: String?
    let sourceUrl: String?
    let sections: [ILSutraSectionDTO]?
}

nonisolated struct ILSutraSectionDTO: Decodable, Sendable {
    let name: String
    let startN: Int
    let lineCount: Int
}
