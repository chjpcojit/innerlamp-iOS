//
//  ILMemorialProductVectorTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Runs the product's three shared vector files unchanged (D6). They are copied by
/// `Scripts/sync-product-vectors.sh` and read from the repo, never restated as literals here.
final class ILMemorialProductVectorTests: XCTestCase {

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        return calendar
    }()

    private func cases(_ name: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name).json")
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(root["cases"] as? [[String: Any]])
    }

    private func date(_ string: String) throws -> Date {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        let value = try XCTUnwrap(parts.count == 3 ? parts : nil)
        return try XCTUnwrap(
            Self.calendar.date(from: DateComponents(year: value[0], month: value[1], day: value[2], hour: 9))
        )
    }

    private func dayString(_ date: Date) -> String {
        let components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    // MARK: - death-date-conversion.json

    func test_deathDateConversionVectors() throws {
        for vector in try cases("death-date-conversion") {
            let name = vector["name"] as? String ?? "?"
            let input = try XCTUnwrap(vector["input"] as? [String: Any])
            let expected = try XCTUnwrap(vector["expected"] as? [String: Any])

            if let solar = input["solar"] as? String {
                let parts = solar.split(separator: "-").compactMap { Int($0) }
                let lunar = ILLunarCalendar.solarToLunar(day: parts[2], month: parts[1], year: parts[0])
                let wanted = try XCTUnwrap(expected["lunar"] as? [String: Any], name)
                XCTAssertEqual(lunar.day, wanted["day"] as? Int, name)
                XCTAssertEqual(lunar.month, wanted["month"] as? Int, name)
                XCTAssertEqual(lunar.year, wanted["year"] as? Int, name)
                XCTAssertEqual(lunar.isLeapMonth, wanted["leap_month"] as? Bool, name)
            } else if let lunar = input["lunar"] as? [String: Any] {
                let solar = ILLunarCalendar.lunarToSolarExact(
                    day: lunar["day"] as? Int ?? 0,
                    month: lunar["month"] as? Int ?? 0,
                    year: lunar["year"] as? Int ?? 0,
                    isLeap: lunar["leap_month"] as? Bool ?? false
                )
                if expected["valid"] as? Bool == false {
                    XCTAssertNil(solar, name)
                } else {
                    let wanted = try XCTUnwrap(expected["solar"] as? String, name)
                    let actual = try XCTUnwrap(solar, name)
                    XCTAssertEqual(
                        String(format: "%04d-%02d-%02d", actual.year, actual.month, actual.day),
                        wanted,
                        name
                    )
                }
            }
        }
    }

    // MARK: - next-anniversary.json

    func test_nextAnniversaryVectors() throws {
        for vector in try cases("next-anniversary") {
            let name = vector["name"] as? String ?? "?"
            let input = try XCTUnwrap(vector["input"] as? [String: Any])
            let expected = try XCTUnwrap(vector["expected"] as? [String: Any])
            let kind = ILMemorialCalendarKind(rawValue: input["calendar"] as? String ?? "") ?? .solar
            let entry = ILMemorialEntity(
                id: "v",
                name: "Vector",
                relationship: .father,
                calendarKind: kind,
                day: input["day"] as? Int ?? 1,
                month: input["month"] as? Int ?? 1,
                deathYear: input["death_year"] as? Int,
                deathLeapMonth: input["leap_month"] as? Bool ?? false,
                note: "",
                reminder: nil
            )
            let today = try date(try XCTUnwrap(input["today"] as? String))

            let result = ILMemorialDateRules.nextAnniversary(for: entry, now: today, calendar: Self.calendar)
            let actual = try XCTUnwrap(result, name)

            XCTAssertEqual(dayString(actual.date), expected["next_date"] as? String, name)
            XCTAssertEqual(actual.daysUntil, expected["days_left"] as? Int, name)
            XCTAssertEqual(actual.ordinal, expected["ordinal"] as? Int, name)
        }
    }

    // MARK: - anniversary-ordinal.json

    func test_anniversaryOrdinalVectors() throws {
        for vector in try cases("anniversary-ordinal") {
            let name = vector["name"] as? String ?? "?"
            let input = try XCTUnwrap(vector["input"] as? [String: Any])
            let expected = try XCTUnwrap(vector["expected"] as? [String: Any])
            let ordinal = input["ordinal"] as? Int

            XCTAssertEqual(ILMemorialFormatter.ordinalText(ordinal), expected["label"] as? String, name)
        }
    }
}
