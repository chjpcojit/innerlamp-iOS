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
