//
//  ILCalendarEventRepository.swift
//  InnerLamp
//

import Foundation

/// EN: Reads the event calendar of one solar year served by `GET /v1/calendar/events`.
/// VI: Đọc lịch sự kiện của một năm dương lịch từ `GET /v1/calendar/events`.
///
/// EN: Network-only (device copy planned — see Docs/Specs/Calendar/, FR-CAL-007). Every failure is an
///     `ILCatalogError` (`.offline` when the server cannot be reached, `.loadFailed` otherwise).
/// VI: Chỉ gọi mạng (bản lưu trên máy dự kiến — xem Docs/Specs/Calendar/, FR-CAL-007). Mọi lỗi là
///     `ILCatalogError` (`.offline` khi không tới được server, `.loadFailed` cho các trường hợp khác).
nonisolated protocol ILCalendarEventRepository {

    /// Every event and occurrence of `year` (Gregorian, 1/1 → 31/12).
    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity
}
