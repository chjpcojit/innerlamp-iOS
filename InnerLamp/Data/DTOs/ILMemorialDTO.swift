//
//  ILMemorialDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of the memorial book — Data layer. Contract pinned 2026-11-16:
/// `Docs/Specs/Memorial/client-contract.md` (§2), backend `openapi.yaml` 3.1.0.
///
/// Response DTOs have no `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`,
/// which ignores keys the DTO does not declare. `reminder.timezone` and `add_to_os_reminder` are
/// therefore deliberately **not** declared: v1 returns them, v4.0 removes them, and the decoder
/// must work with both (contract §0.2, D3).
nonisolated struct ILMemorialDTO: Decodable, Sendable {
    let id: Int64
    let fullName: String
    let relationship: String
    /// Solar `YYYY-MM-DD`; `nil` when the death year is unknown.
    let deathDate: String?
    let deathCalendar: String
    let deathDay: Int?
    let deathMonth: Int?
    let deathLeapMonth: Bool?
    let note: String?
    /// Signed URL, lives 15 minutes. Never written to Core Data (D8).
    let photoUrl: String?
    let reminder: ILMemorialReminderDTO?
}

nonisolated struct ILMemorialReminderDTO: Decodable, Sendable {
    let daysBefore: Int
    /// 24h `HH:mm`.
    let time: String
}

/// `data` of `GET /v1/memorials` — the whole list, no pagination (the server caps it at 100).
nonisolated struct ILMemorialListDTO: Decodable, Sendable {
    let items: [ILMemorialDTO]
}

/// Body of `POST /v1/memorials` and `PUT /v1/memorials/{id}`. Encoded with a plain `JSONEncoder()`
/// (no key strategy), so the explicit snake_case `CodingKeys` make the body match the contract.
///
/// Only the fields the contract allows are declared. In particular there is **no**
/// `add_to_os_reminder` and **no** `reminder.timezone`: v1 accepts them but v4.0 rejects them with
/// 400 (contract §0.1, D3). `nil` fields are omitted by the synthesized `encodeIfPresent`.
nonisolated struct ILMemorialRequestDTO: Encodable, Equatable, Sendable {
    let fullName: String
    let relationship: String
    let deathCalendar: String
    /// Solar `YYYY-MM-DD`. Sent only when the death year is known; mutually exclusive with
    /// `deathDay` / `deathMonth` / `deathLeapMonth`.
    let deathDate: String?
    let deathDay: Int?
    let deathMonth: Int?
    /// Lunar only, and only when `deathDate` is absent.
    let deathLeapMonth: Bool?
    let note: String
    let reminder: ILMemorialReminderRequestDTO?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case relationship
        case deathCalendar = "death_calendar"
        case deathDate = "death_date"
        case deathDay = "death_day"
        case deathMonth = "death_month"
        case deathLeapMonth = "death_leap_month"
        case note
        case reminder
    }
}

nonisolated struct ILMemorialReminderRequestDTO: Encodable, Equatable, Sendable {
    let daysBefore: Int
    let time: String

    enum CodingKeys: String, CodingKey {
        case daysBefore = "days_before"
        case time
    }
}
