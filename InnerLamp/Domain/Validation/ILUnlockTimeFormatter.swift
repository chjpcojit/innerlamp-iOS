//
//  ILUnlockTimeFormatter.swift
//  InnerLamp
//

import Foundation

/// Renders the server's ISO-8601 lock timestamps (`details.locked_until`) as a local `HH:mm`
/// clock time.
///
/// Shared by the SignUp and Otp feature errors, both of which build a 429 lock/limited message
/// from the same `details.locked_until` value. Returns `nil` when the value is missing or
/// unparseable, so callers fall back to a message without a time rather than showing a raw
/// timestamp. Foundation only.
enum ILUnlockTimeFormatter {

    static func displayString(from isoString: String?) -> String? {
        guard let isoString else { return nil }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = parser.date(from: isoString)
        if date == nil {
            parser.formatOptions = [.withInternetDateTime]
            date = parser.date(from: isoString)
        }
        guard let date else { return nil }

        let display = DateFormatter()
        display.locale = Locale(identifier: "vi_VN")
        display.timeZone = .current
        display.dateFormat = "HH:mm"
        return display.string(from: date)
    }
}
