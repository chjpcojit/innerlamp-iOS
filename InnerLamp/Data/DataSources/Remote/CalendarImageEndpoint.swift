//
//  CalendarImageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/calendar/image?date=YYYY-MM-DD`. Returns `ILCalendarImageDTO`.
///
/// Public endpoint: `requiresAuth == false`. `date` is a **solar** date in 1900...2100; anything else
/// is `400 INVALID_DATE`. iOS always sends it (omitting it makes the server use today in
/// `Asia/Ho_Chi_Minh`, which would not match the day the screen shows).
nonisolated struct CalendarImageEndpoint: Endpoint {
    /// `yyyy-MM-dd`.
    let date: String

    var queryParameters: [String: String]? { ["date": date] }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/calendar/image" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
