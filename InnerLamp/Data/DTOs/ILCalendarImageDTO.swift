//
//  ILCalendarImageDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of `GET /v1/calendar/image` — Data layer. Contract:
/// `Docs/Specs/LunarDayDetail/design.md` → "API contract" (confirmed by the backend team,
/// 2026-10-07).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. A DTO never escapes
/// the Data layer.
nonisolated struct ILCalendarImageDTO: Decodable, Sendable {
    /// Echo of the requested solar date (`yyyy-MM-dd`).
    let date: String
    let id: String
    let imageUrl: String
    let author: String
    let license: String
    let licenseUrl: String?
    let sourceUrl: String?
}
