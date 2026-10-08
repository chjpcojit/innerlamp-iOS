//
//  ILLunarCalendarTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 27/9/26.
//

import XCTest
@testable import InnerLamp

final class ILLunarCalendarTests: XCTestCase {

    // MARK: - Can Chi of the day (spec section 1)

    func test_dayCanChiIndices_matchesKnownReference() {
        // 2024-01-01 → JD 2460311 → can = (2460311 + 9) % 10 = 0 (Giáp),
        // chi = (2460311 + 1) % 12 = 0 (Tý).
        let indices = ILLunarCalendar.dayCanChiIndices(day: 1, month: 1, year: 2024)
        XCTAssertEqual(indices.can, 0)
        XCTAssertEqual(indices.chi, 0)
    }

    func test_dayCanChiIndices_advancesOnePerDay() {
        // Consecutive days advance both Can and Chi by one (mod cycle).
        let first = ILLunarCalendar.dayCanChiIndices(day: 1, month: 1, year: 2024)
        let next = ILLunarCalendar.dayCanChiIndices(day: 2, month: 1, year: 2024)
        XCTAssertEqual(next.can, (first.can + 1) % 10)
        XCTAssertEqual(next.chi, (first.chi + 1) % 12)
    }

    // MARK: - Day Hoàng đạo / Hắc đạo (spec section 2)

    func test_isHoangDao_sixGoodDaysPerMonth_followingTwelveStars() {
        // For any fixed lunar month, 12 consecutive days contain exactly 6 good days, at the
        // 6 good-star chi positions {0,1,4,5,8,9} shifted by ((lunarMonth - 1) % 6) * 2.
        for lunarMonth in 1...12 {
            let shift = ((lunarMonth - 1) % 6) * 2
            var goodCount = 0
            for day in 1...12 {
                let chi = ILLunarCalendar.dayCanChiIndices(day: day, month: 1, year: 2024).chi
                let expected = [0, 1, 4, 5, 8, 9].contains((chi - shift + 12) % 12)
                let actual = ILLunarCalendar.isHoangDao(
                    solarDay: day, solarMonth: 1, solarYear: 2024, lunarMonth: lunarMonth
                )
                XCTAssertEqual(actual, expected, "lunarMonth \(lunarMonth) solarDay \(day)")
                if actual { goodCount += 1 }
            }
            XCTAssertEqual(goodCount, 6, "lunarMonth \(lunarMonth)")
        }
    }

    // MARK: - Good hours of the day (spec section 3)

    func test_goodHourChiIndices_matchesClassicalRule() {
        // Thanh Long starts per the day's branch then runs forward, yielding exactly two
        // hour patterns: even branches → Tý/Sửu/Thìn/Tỵ/Thân/Dậu, odd → Dần/Mão/Ngọ/Mùi/Tuất/Hợi.
        let evenBranches: [Int] = [0, 1, 4, 5, 8, 9]
        let oddBranches: [Int] = [2, 3, 6, 7, 10, 11]
        let expected: [Int: [Int]] = [
            0: evenBranches, 2: evenBranches, 4: evenBranches, 6: evenBranches, 8: evenBranches, 10: evenBranches,
            1: oddBranches, 3: oddBranches, 5: oddBranches, 7: oddBranches, 9: oddBranches, 11: oddBranches
        ]
        for dayChi in 0..<12 {
            XCTAssertEqual(
                ILLunarCalendar.goodHourChiIndices(dayChiIndex: dayChi),
                expected[dayChi],
                "dayChi \(dayChi)"
            )
        }
    }

    func test_goodHourChiIndices_alwaysSixDistinctHours() {
        for dayChi in 0..<12 {
            let hours = ILLunarCalendar.goodHourChiIndices(dayChiIndex: dayChi)
            XCTAssertEqual(hours.count, 6, "dayChi \(dayChi)")
            XCTAssertEqual(Set(hours).count, 6, "dayChi \(dayChi)")
            XCTAssertTrue(hours.allSatisfy { (0..<12).contains($0) }, "dayChi \(dayChi)")
        }
    }

    // MARK: - Clashing ages (spec section 4)

    func test_clashChiIndex_isOppositeBranch() {
        XCTAssertEqual(ILLunarCalendar.clashChiIndex(dayChiIndex: 0), 6)  // Tý ↔ Ngọ
        XCTAssertEqual(ILLunarCalendar.clashChiIndex(dayChiIndex: 6), 0)  // Ngọ ↔ Tý
        XCTAssertEqual(ILLunarCalendar.clashChiIndex(dayChiIndex: 2), 8)  // Dần ↔ Thân
        XCTAssertEqual(ILLunarCalendar.clashChiIndex(dayChiIndex: 11), 5) // Hợi ↔ Tỵ
    }

    func test_clashCanIndices_giapDayYieldsCanhAndMau() {
        // Ngày Giáp (0) → Canh (6, Thiên Can xung) + Mậu (4, Ngũ hành khắc) → Canh Ngọ / Mậu Ngọ.
        XCTAssertEqual(ILLunarCalendar.clashCanIndices(dayCanIndex: 0), [6, 4])
        // Ất (1) → Tân (7) + Kỷ (5).
        XCTAssertEqual(ILLunarCalendar.clashCanIndices(dayCanIndex: 1), [7, 5])
        // Can (9) → (9 + 6) % 10 = 5, (9 + 4) % 10 = 3.
        XCTAssertEqual(ILLunarCalendar.clashCanIndices(dayCanIndex: 9), [5, 3])
    }

    // MARK: - Directions (spec section 5)

    func test_joyStarDirection_byCanPair() {
        XCTAssertEqual(ILLunarCalendar.joyStarDirection(dayCanIndex: 0), "lunarCalendar.direction.northeast".localized) // Giáp
        XCTAssertEqual(ILLunarCalendar.joyStarDirection(dayCanIndex: 5), "lunarCalendar.direction.northeast".localized) // Kỷ
        XCTAssertEqual(ILLunarCalendar.joyStarDirection(dayCanIndex: 1), "lunarCalendar.direction.northwest".localized) // Ất
        XCTAssertEqual(ILLunarCalendar.joyStarDirection(dayCanIndex: 3), "lunarCalendar.direction.south".localized)     // Đinh
        XCTAssertEqual(ILLunarCalendar.joyStarDirection(dayCanIndex: 9), "lunarCalendar.direction.southeast".localized) // Quý
    }

    func test_wealthStarDirection_quyIsNorthwest() {
        // Quý (9) → Tây Bắc (northwest).
        XCTAssertEqual(ILLunarCalendar.wealthStarDirection(dayCanIndex: 9), "lunarCalendar.direction.northwest".localized)
        XCTAssertEqual(ILLunarCalendar.wealthStarDirection(dayCanIndex: 0), "lunarCalendar.direction.southeast".localized) // Giáp
        XCTAssertEqual(ILLunarCalendar.wealthStarDirection(dayCanIndex: 4), "lunarCalendar.direction.north".localized)     // Mậu
        XCTAssertEqual(ILLunarCalendar.wealthStarDirection(dayCanIndex: 8), "lunarCalendar.direction.west".localized)      // Nhâm
    }

    // MARK: - Hạc thần (hướng xấu cần tránh)

    func test_sexagenaryDayIndex_matchesKnownReferences() {
        XCTAssertEqual(ILLunarCalendar.sexagenaryDayIndex(can: 0, chi: 0), 0)    // Giáp Tý
        XCTAssertEqual(ILLunarCalendar.sexagenaryDayIndex(can: 1, chi: 1), 1)    // Ất Sửu
        XCTAssertEqual(ILLunarCalendar.sexagenaryDayIndex(can: 0, chi: 8), 20)   // Giáp Thân
        XCTAssertEqual(ILLunarCalendar.sexagenaryDayIndex(can: 9, chi: 5), 29)   // Quý Tỵ
        XCTAssertEqual(ILLunarCalendar.sexagenaryDayIndex(can: 9, chi: 11), 59)  // Quý Hợi
    }

    func test_craneStarDirection_matchesReferenceTable() {
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 0, chi: 0), "lunarCalendar.direction.southeast".localized) // Giáp Tý → Đông Nam
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 2, chi: 2), "lunarCalendar.direction.south".localized)      // Bính Dần → Nam
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 7, chi: 7), "lunarCalendar.direction.southwest".localized)  // Tân Mùi → Tây Nam
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 3, chi: 1), "lunarCalendar.direction.west".localized)       // Đinh Sửu → Tây
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 8, chi: 6), "lunarCalendar.direction.northwest".localized)  // Nhâm Ngọ → Tây Bắc
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 4, chi: 0), "lunarCalendar.direction.north".localized)      // Mậu Tý → Bắc
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 5, chi: 9), "lunarCalendar.direction.northeast".localized)  // Kỷ Dậu → Đông Bắc
        XCTAssertEqual(ILLunarCalendar.craneStarDirection(can: 1, chi: 3), "lunarCalendar.direction.east".localized)       // Ất Mão → Đông
        XCTAssertNil(ILLunarCalendar.craneStarDirection(can: 9, chi: 5))                                                    // Quý Tỵ → bận việc trên trời
    }

    func test_craneStarDirection_60DayCycleHas16NoneAnd8Directions() {
        var nilCount = 0
        var directions = Set<String>()
        for n in 0..<60 {
            if let direction = ILLunarCalendar.craneStarDirection(can: n % 10, chi: n % 12) {
                directions.insert(direction)
            } else {
                nilCount += 1
            }
        }
        XCTAssertEqual(nilCount, 16)
        XCTAssertEqual(directions.count, 8)
    }

    // MARK: - Tiết khí (24 solar terms)

    func test_solarTermName_has24DistinctNames() {
        let names = (0..<24).map(ILLunarCalendar.solarTermName)
        XCTAssertEqual(names.count, 24)
        XCTAssertEqual(Set(names).count, 24)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
    }

    func test_solarTermIndex_cyclesThroughAll24TermsAcrossYear() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        var seen = Set<Int>()
        for offset in 0..<366 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let c = calendar.dateComponents([.day, .month, .year], from: date)
            let index = ILLunarCalendar.solarTermIndex(
                solarDay: c.day ?? 1, solarMonth: c.month ?? 1, solarYear: c.year ?? 2024
            )
            XCTAssertTrue((0..<24).contains(index), "date \(date)")
            seen.insert(index)
        }
        XCTAssertEqual(seen.count, 24, "a full year must visit every solar term")
    }

    // MARK: - 12 Trực

    func test_trucName_has12DistinctNames() {
        let names = (0..<12).map(ILLunarCalendar.trucName)
        XCTAssertEqual(Set(names).count, 12)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
    }

    func test_trucIndex_matchesSpecFormula() {
        // truc = (ChiDay - ChiKien) % 12, ChiKien = (lunarMonth + 1) % 12.
        for lunarMonth in 1...12 {
            let chiKien = (lunarMonth + 1) % 12
            for day in 1...12 {
                let chiDay = ILLunarCalendar.dayCanChiIndices(day: day, month: 1, year: 2024).chi
                let expected = ((chiDay - chiKien) % 12 + 12) % 12
                XCTAssertEqual(
                    ILLunarCalendar.trucIndex(solarDay: day, solarMonth: 1, solarYear: 2024, lunarMonth: lunarMonth),
                    expected,
                    "lunarMonth \(lunarMonth) solarDay \(day)"
                )
            }
        }
    }

    // MARK: - 28 Tú

    func test_star28Name_has28DistinctNames() {
        let names = (0..<28).map(ILLunarCalendar.star28Name)
        XCTAssertEqual(Set(names).count, 28)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
    }

    func test_star28Index_advancesOnePerDay() {
        for day in 1...27 {
            let current = ILLunarCalendar.star28Index(solarDay: day, solarMonth: 1, solarYear: 2024)
            let next = ILLunarCalendar.star28Index(solarDay: day + 1, solarMonth: 1, solarYear: 2024)
            XCTAssertEqual(next, (current + 1) % 28, "day \(day)")
        }
    }

    // MARK: - Short-month rule (day 30 falls on day 29 of a 29-day month)

    func test_isLastDayOfShortMonth_trueOnlyOnDay29FollowedByDay1() {
        let calendar = Calendar(identifier: .gregorian)
        var day = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1)) ?? Date()
        var sawShort = false
        var sawLong = false

        for _ in 0..<(365 * 3) {
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let nextLunar = ILLunarCalendar.solarToLunar(date: next, calendar: calendar)
            let expected = lunar.day == 29 && nextLunar.day == 1

            XCTAssertEqual(ILLunarCalendar.isLastDayOfShortMonth(lunar, on: day, calendar: calendar), expected)
            sawShort = sawShort || expected
            sawLong = sawLong || (lunar.day == 30)
            day = next
        }
        XCTAssertTrue(sawShort && sawLong, "Scan range must contain both short and long lunar months")
    }

    func test_matchesLunarDay_day30MatchesLastDayOfEveryMonth() {
        let calendar = Calendar(identifier: .gregorian)
        var day = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1)) ?? Date()
        var lastDays = 0

        for _ in 0..<(365 * 3) {
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let isLastDay = ILLunarCalendar.solarToLunar(date: next, calendar: calendar).day == 1

            XCTAssertEqual(
                ILLunarCalendar.matchesLunarDay(30, lunar: lunar, on: day, calendar: calendar),
                isLastDay && lunar.day >= 29,
                "30 must match exactly the last day of a 29/30-day month"
            )
            if isLastDay { lastDays += 1 }
            day = next
        }
        XCTAssertGreaterThan(lastDays, 30)
    }

    func test_matchesLunarDay_nonThirtyTargetsRequireExactDay() {
        let lunar = ILLunarCalendar.LunarDate(day: 29, month: 7, year: 2024, isLeapMonth: false)
        XCTAssertFalse(ILLunarCalendar.matchesLunarDay(15, lunar: lunar, on: Date()))
        XCTAssertTrue(ILLunarCalendar.matchesLunarDay(29, lunar: lunar, on: Date()))
    }
}
