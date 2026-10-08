//
//  ILMemorialDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of the memorial book — Data layer. Contract: `docs/specs/api/openapi.yaml`
/// (`/v1/memorials`, schemas `Memorial` / `MemorialRequest`) in the backend repo.
///
/// Response DTOs have no `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`.
/// Enum-like fields stay `String` so an unknown server value never fails the whole list;
/// `ILMemorialMapper` maps them. `photo_url`, `created_at` and `updated_at` are not decoded —
/// the portrait is not built (`TD-Memorial-002`) and the list order is derived locally.
nonisolated struct ILMemorialDTO: Decodable, Sendable {
    let id: Int
    let fullName: String
    let relationship: String
    /// Solar `YYYY-MM-DD`; `nil` when the death year is unknown.
    let deathDate: String?
    let deathCalendar: String
    let deathDay: Int?
    let deathMonth: Int?
    let deathLeapMonth: Bool?
    let note: String?
    let reminder: ILMemorialReminderDTO?
    let addToOsReminder: Bool
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
/// The server rejects unknown fields, so only contract fields exist here, and `nil` fields are
/// omitted (synthesized `encodeIfPresent`).
nonisolated struct ILMemorialRequestDTO: Encodable, Equatable, Sendable {
    let fullName: String
    let relationship: String
    let deathCalendar: String
    /// Solar `YYYY-MM-DD`. Sent only when the death year is known; mutually exclusive with
    /// `deathDay` / `deathMonth` / `deathLeapMonth`.
    let deathDate: String?
    let deathDay: Int?
    let deathMonth: Int?
    let deathLeapMonth: Bool?
    let note: String
    let reminder: ILMemorialReminderRequestDTO?
    /// Only valid with a `reminder` — the mapper forces `false` otherwise.
    let addToOsReminder: Bool

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
        case addToOsReminder = "add_to_os_reminder"
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
