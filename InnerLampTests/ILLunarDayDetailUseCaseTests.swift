//
//  ILLunarDayDetailUseCaseTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 27/9/26.
//

import XCTest
@testable import InnerLamp

final class ILLunarDayDetailUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let sut = ILLunarDayDetailUseCaseImpl()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    func test_getDetail_computesLunarDateForTet() {
        // 10/2/2024 = mùng 1 tháng Giêng (Tết Giáp Thìn) — xem ILLunarCalendarUseCaseTests.
        let entity = sut.getDetail(for: date(2024, 2, 10))

        XCTAssertEqual(entity.lunarDay, 1)
        XCTAssertEqual(entity.lunarMonth, 1)
        XCTAssertEqual(entity.lunarYear, 2024)
        XCTAssertFalse(entity.isLunarLeapMonth)
        XCTAssertEqual(entity.solarDay, 10)
        XCTAssertEqual(entity.solarMonth, 2)
        XCTAssertEqual(entity.solarYear, 2024)
    }

    func test_getDetail_computesFullMoon() {
        // 24/2/2024 = rằm tháng Giêng (15/1 âm).
        let entity = sut.getDetail(for: date(2024, 2, 24))

        XCTAssertEqual(entity.lunarDay, 15)
        XCTAssertEqual(entity.lunarMonth, 1)
    }

    func test_getDetail_alwaysHasSixGoodHours() {
        for day in [1, 10, 20, 28] {
            let entity = sut.getDetail(for: date(2024, 9, day))
            XCTAssertEqual(entity.goodHourChiIndices.count, 6, "solar day \(day)")
        }
    }

    func test_getDetail_clashChiIsOppositeOfDayChi() {
        let entity = sut.getDetail(for: date(2024, 9, 17))

        XCTAssertEqual(entity.clashChiIndex, (entity.dayChiIndex + 6) % 12)
    }

    func test_getDetail_hoangDaoMatchesCalendarHelper() {
        let entity = sut.getDetail(for: date(2024, 9, 17))

        XCTAssertEqual(
            entity.isHoangDao,
            ILLunarCalendar.isHoangDao(
                solarDay: 17,
                solarMonth: 9,
                solarYear: 2024,
                lunarMonth: entity.lunarMonth
            )
        )
    }

    func test_dayStar_goodStarsMatchIsHoangDaoAndHaveNames() {
        // 6 sao Hoàng đạo {0,1,4,5,8,9} → isGoodDayStar == true; 6 sao Hắc đạo → false.
        let goodStars = [0, 1, 4, 5, 8, 9]
        for index in 0..<12 {
            XCTAssertEqual(ILLunarCalendar.isGoodDayStar(index), goodStars.contains(index), "index \(index)")
            XCTAssertFalse(ILLunarCalendar.dayStarName(index).isEmpty, "index \(index)")
        }
    }

    func test_getDetail_verseIsPopulated() {
        let entity = sut.getDetail(for: date(2024, 9, 17))

        XCTAssertFalse(entity.verseLines.isEmpty)
        XCTAssertFalse(entity.verseSource.isEmpty)
    }

    func test_verse_selectionFollowsLunarDayPlusMonthModulo() {
        // (1 + 1) % 4 = 2 → verse index 2.
        let verse2 = ILLunarDayDetailUseCaseImpl.verse(forLunarDay: 1, lunarMonth: 1)
        XCTAssertEqual(verse2.source, "lunarDayDetail.verse.2.source".localized)

        // (16 + 7) % 4 = 23 % 4 = 3 → verse index 3.
        let verse3 = ILLunarDayDetailUseCaseImpl.verse(forLunarDay: 16, lunarMonth: 7)
        XCTAssertEqual(verse3.source, "lunarDayDetail.verse.3.source".localized)
    }

    func test_getDetail_directionsAreResolved() {
        let entity = sut.getDetail(for: date(2024, 9, 17))

        XCTAssertFalse(entity.joyStarDirection.isEmpty)
        XCTAssertFalse(entity.wealthStarDirection.isEmpty)
    }

    // MARK: - Variation across days

    /// The three user-facing "computed" sections — giờ hoàng đạo (good hours), tuổi xung khắc
    /// (clashing ages) and hướng xuất hành (Hỷ/Tài thần directions) — must change with the day.
    /// Otherwise the detail screen reads as static/placeholder data. Twelve consecutive days cover
    /// a full Địa Chi cycle (and the 10-day Thiên Can cycle), enough to exercise every value.
    func test_getDetail_goodHoursClashAndDirectionsVaryAcrossDays() {
        let entities = (1...12).map { sut.getDetail(for: date(2024, 9, $0)) }

        XCTAssertGreaterThan(Set(entities.map(\.goodHourChiIndices)).count, 1,
                             "good hours should differ across days")
        XCTAssertGreaterThan(Set(entities.map(\.clashChiIndex)).count, 1,
                             "clashing age (Địa Chi) should differ across days")
        XCTAssertGreaterThan(Set(entities.map(\.dayCanIndex)).count, 1,
                             "clashing ages' Thiên Can should differ across days")
        XCTAssertGreaterThan(Set(entities.map(\.joyStarDirection)).count, 1,
                             "Hỷ thần direction should differ across days")
        XCTAssertGreaterThan(Set(entities.map(\.wealthStarDirection)).count, 1,
                             "Tài thần direction should differ across days")
    }

    /// Every per-day computed field on the entity must vary across a 12-day window — not only the
    /// three headline sections. Lunar month/year change on a slower cadence and are covered by
    /// `test_getDetail_lunarMonthAndYearVaryAcrossMonths`.
    func test_getDetail_allPerDayFieldsVaryAcrossDays() {
        let entities = (1...12).map { sut.getDetail(for: date(2024, 9, $0)) }

        XCTAssertGreaterThan(Set(entities.map(\.lunarDay)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.isHoangDao)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.dayCanIndex)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.dayChiIndex)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.goodHourChiIndices)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.clashChiIndex)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.joyStarDirection)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.wealthStarDirection)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.verseSource)).count, 1)
    }

    /// Lunar month and year only change across month/year boundaries — sample the 15th of each
    /// solar month across a full year.
    func test_getDetail_lunarMonthAndYearVaryAcrossMonths() {
        let entities = (1...12).map { sut.getDetail(for: date(2024, $0, 15)) }

        XCTAssertGreaterThan(Set(entities.map(\.lunarMonth)).count, 1)
        XCTAssertGreaterThan(Set(entities.map(\.lunarYear)).count, 1)
    }
}
