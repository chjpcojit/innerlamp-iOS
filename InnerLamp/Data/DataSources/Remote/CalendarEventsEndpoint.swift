//
//  CalendarEventsEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/calendar/events?year=YYYY`. Returns `ILCalendarEventsDTO` (every event
/// and occurrence of one whole solar year, 1/1 → 31/12).
///
/// Public endpoint (openapi 2.2.0, FR-CAL-001): `requiresAuth == false`, so guests can read the
/// calendar. No `X-API-Key` either — that header is for the website and is rejected from mobile
/// (`401 INVALID_API_KEY`). Rate limited per IP: `429 RATE_LIMITED` with
/// `details.retry_after_seconds`. `year` is 1900...2100; anything else is `400 INVALID_YEAR`. iOS
/// always sends it so the response is cacheable per year (`Cache-Control: public, max-age=86400`;
/// omitting it makes the server use the current year in `Asia/Ho_Chi_Minh`, `no-cache`).
nonisolated struct CalendarEventsEndpoint: Endpoint {
    let year: Int

    var queryParameters: [String: String]? { ["year": String(year)] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/calendar/events" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
