//
//  ILCalendarEventEntity.swift
//  InnerLamp
//

import Foundation

/// One solar year of the backend's event calendar (`GET /v1/calendar/events`) — Domain layer.
/// Raw server values only; display formatting belongs to the ViewModel.
nonisolated struct ILCalendarEventsEntity: Equatable {
    let year: Int
    let groups: [ILCalendarGroupEntity]
    /// Each event once; look one up through `ILCalendarOccurrenceEntity.eventCode`.
    let events: [ILCalendarEventEntity]
    /// Chronological (the order the server sent).
    let occurrences: [ILCalendarOccurrenceEntity]
}

/// A label an event can belong to ("Phật giáo", "Việt Nam", "Dân gian"…). The backend may add more
/// codes later, so callers must not assume a closed set.
nonisolated struct ILCalendarGroupEntity: Equatable {
    let code: String
    let name: String
}

nonisolated struct ILCalendarEventEntity: Equatable {
    let code: String
    let name: String
    let shortDescription: String
    let longDescription: String
    /// Ritual guidance ("Cúng gia tiên, chúc Tết…"); may be empty.
    let guidance: String
    /// `nil` until the owner supplies an image.
    let imageURL: String?
    /// Group codes, in display order.
    let groupCodes: [String]
    let isPublicHoliday: Bool
    /// BR-CAL-10: one of the "Lễ lớn". Data from the server, never a client list.
    let isMajor: Bool
    /// Order within one solar day (ascending); Mùng 1 and Rằm are always last.
    let sortOrder: Int
    let recurrence: ILCalendarRecurrence
}

/// How an event repeats. Open set: a value the app does not know decodes as `.other`.
nonisolated enum ILCalendarRecurrence: Equatable {
    case solar
    case lunar
    /// Mùng 1 and Rằm — every lunar month (BR-CAL-05). The way to recognise them, instead of
    /// comparing `code` or computing the lunar day locally.
    case lunarMonthly
    case lunarLastDay
    case solarTerm
    case other

    init(rawValue: String) {
        switch rawValue {
        case "solar": self = .solar
        case "lunar": self = .lunar
        case "lunar_monthly": self = .lunarMonthly
        case "lunar_last_day": self = .lunarLastDay
        case "solar_term": self = .solarTerm
        default: self = .other
        }
    }
}

/// One event on one solar day, with its lunar date.
nonisolated struct ILCalendarOccurrenceEntity: Equatable {
    let eventCode: String
    /// Start of the solar day in the device calendar (parsed from the server's `yyyy-MM-dd`).
    let solarDate: Date
    let lunarDay: Int
    let lunarMonth: Int
    let isLeapMonth: Bool
}
