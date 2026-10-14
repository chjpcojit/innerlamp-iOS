//
//  CalendarEventsEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/calendar/events?year=YYYY`. Returns `ILCalendarEventsDTO` (every event
/// and occurrence of one whole solar year, 1/1 → 31/12).
///
/// Requires the access token (`requiresAuth` keeps its default `true`). `year` is 1900...2100;
/// anything else is `400 INVALID_YEAR`. iOS always sends it so the response can be cached per year
/// (omitting it makes the server use the current year in `Asia/Ho_Chi_Minh`).
nonisolated struct CalendarEventsEndpoint: Endpoint {
    let year: Int

    var queryParameters: [String: String]? { ["year": String(year)] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/calendar/events" }
    var method: HTTPMethod { .get }
}
