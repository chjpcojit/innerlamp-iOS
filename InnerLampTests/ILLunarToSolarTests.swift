//
//  ILLunarToSolarTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILLunarToSolarTests: XCTestCase {

    // MARK: - Known dates

    func test_tetNguyenDan_matchesPublishedSolarDates() {
        XCTAssertEqual(ILLunarCalendar.lunarToSolar(day: 1, month: 1, year: 2024), ILLunarCalendar.SolarDate(day: 10, month: 2, year: 2024))
        XCTAssertEqual(ILLunarCalendar.lunarToSolar(day: 1, month: 1, year: 2025), ILLunarCalendar.SolarDate(day: 29, month: 1, year: 2025))
        XCTAssertEqual(ILLunarCalendar.lunarToSolar(day: 1, month: 1, year: 2026), ILLunarCalendar.SolarDate(day: 17, month: 2, year: 2026))
    }

    func test_ramThangBay_2024_isAugust18() {
        XCTAssertEqual(ILLunarCalendar.lunarToSolar(day: 15, month: 7, year: 2024), ILLunarCalendar.SolarDate(day: 18, month: 8, year: 2024))
    }

    // MARK: - Round trip

    func test_roundTrip_everyRegularDayOf2025() throws {
        let calendar = Calendar(identifier: .gregorian)
        var date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)))
        for _ in 0..<365 {
            let lunar = ILLunarCalendar.solarToLunar(date: date, calendar: calendar)
            if !lunar.isLeapMonth {
                let solar = ILLunarCalendar.lunarToSolar(day: lunar.day, month: lunar.month, year: lunar.year)
                let parts = calendar.dateComponents([.day, .month, .year], from: date)
                XCTAssertEqual(solar, ILLunarCalendar.SolarDate(day: parts.day ?? 0, month: parts.month ?? 0, year: parts.year ?? 0),
                               "lunar \(lunar) did not round-trip")
            }
            date = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: date))
        }
    }

    // MARK: - Short months

    func test_day30_inEveryMonth_resolvesInsideThatLunarMonth() throws {
        let calendar = Calendar(identifier: .gregorian)
        for month in 1...12 {
            let solar = try XCTUnwrap(ILLunarCalendar.lunarToSolar(day: 30, month: month, year: 2025), "month \(month)")
            let date = try XCTUnwrap(calendar.date(from: DateComponents(year: solar.year, month: solar.month, day: solar.day)))
            let lunar = ILLunarCalendar.solarToLunar(date: date, calendar: calendar)
            XCTAssertEqual(lunar.month, month, "day 30 of month \(month) spilled into month \(lunar.month)")
            XCTAssertTrue([29, 30].contains(lunar.day), "month \(month) resolved to lunar day \(lunar.day)")
        }
    }

    // MARK: - Leap months

    func test_leapMonth_2025_exists_andRoundTrips() throws {
        let solar = try XCTUnwrap(ILLunarCalendar.lunarToSolar(day: 1, month: 6, year: 2025, isLeap: true))
        let lunar = ILLunarCalendar.solarToLunar(day: solar.day, month: solar.month, year: solar.year)
        XCTAssertTrue(lunar.isLeapMonth)
        XCTAssertEqual(lunar.month, 6)
        XCTAssertEqual(lunar.day, 1)
    }

    func test_leapMonth_inYearWithoutIt_isNil() {
        XCTAssertNil(ILLunarCalendar.lunarToSolar(day: 1, month: 6, year: 2024, isLeap: true))
    }

    func test_regularMonth_ofLeapYear_stillResolves() {
        XCTAssertNotNil(ILLunarCalendar.lunarToSolar(day: 15, month: 6, year: 2025))
    }

    // MARK: - Invalid input

    func test_invalidDayOrMonth_isNil() {
        XCTAssertNil(ILLunarCalendar.lunarToSolar(day: 0, month: 1, year: 2025))
        XCTAssertNil(ILLunarCalendar.lunarToSolar(day: 31, month: 1, year: 2025))
        XCTAssertNil(ILLunarCalendar.lunarToSolar(day: 1, month: 13, year: 2025))
    }
}
