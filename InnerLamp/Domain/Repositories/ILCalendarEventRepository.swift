//
//  ILCalendarEventRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the event calendar of one solar year served by `GET /v1/calendar/events`.
///
/// Network-only (no local cache yet — see TD-Home-003). Every failure is an `ILCatalogError`
/// (`.offline` when the server cannot be reached, `.loadFailed` otherwise).
nonisolated protocol ILCalendarEventRepository {

    /// Every event and occurrence of `year` (Gregorian, 1/1 → 31/12).
    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity
}
