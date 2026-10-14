//
//  ILCalendarEventsDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of `GET /v1/calendar/events` — Data layer. Contract: `Docs/Specs/Home/design.md`
/// → "API contract" (backend `docs/specs/features/calendar/api-contract.md` v2.1).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. A DTO never escapes
/// the Data layer.
nonisolated struct ILCalendarEventsDTO: Decodable, Sendable {
    let year: Int
    let groups: [ILCalendarGroupDTO]
    /// Each event once; occurrences point at it by `code`.
    let events: [ILCalendarEventDTO]
    /// Sorted by `solarDate`, then display order, then code.
    let occurrences: [ILCalendarOccurrenceDTO]
}

nonisolated struct ILCalendarGroupDTO: Decodable, Sendable {
    let code: String
    let name: String
}

nonisolated struct ILCalendarEventDTO: Decodable, Sendable {
    let code: String
    let name: String
    let shortDescription: String
    let longDescription: String
    let guidance: String
    /// Always present, `null` until the owner supplies an image.
    let imageUrl: String?
    let groups: [String]
    let isPublicHoliday: Bool
}

nonisolated struct ILCalendarOccurrenceDTO: Decodable, Sendable {
    let eventCode: String
    /// `yyyy-MM-dd`, always inside the response `year`.
    let solarDate: String
    let lunarDate: ILCalendarLunarDateDTO
}

nonisolated struct ILCalendarLunarDateDTO: Decodable, Sendable {
    let day: Int
    let month: Int
    /// The **lunar** year — can be `year - 1` for a 12th-month event in January/February.
    let year: Int
    let isLeapMonth: Bool
}
