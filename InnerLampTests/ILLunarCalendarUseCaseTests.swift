//
//  ILLunarCalendarUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILLunarCalendarUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func makeSUT(today: Date) -> ILLunarCalendarUseCaseImpl {
        ILLunarCalendarUseCaseImpl(calendar: calendar, now: { today })
    }

    func test_getInitialState_buildsSixConsecutiveMonthsStartingFromCurrentMonth() {
        let entity = makeSUT(today: date(2024, 11, 20)).getInitialState()

        XCTAssertEqual(entity.months.map(\.id), ["2024-11", "2024-12", "2025-01", "2025-02", "2025-03", "2025-04"])
    }

    func test_getInitialState_selectsTodayAndFillsMonthLayout() {
        // 1/2/2024 là thứ Năm ⇒ tuần bắt đầu Chủ nhật có 4 ô trống (CN, T2, T3, T4).
        let entity = makeSUT(today: date(2024, 2, 10)).getInitialState()

        XCTAssertEqual(entity.todayID, "2024-02-10")
        XCTAssertEqual(entity.selectedDayID, "2024-02-10")
        let february = entity.months[0]
        XCTAssertEqual(february.days.count, 29) // 2024 là năm nhuận
        XCTAssertEqual(february.leadingBlankDays, 4)
        XCTAssertEqual(february.days.first?.id, "2024-02-01")
        XCTAssertEqual(february.days.last?.id, "2024-02-29")
    }

    func test_getInitialState_computesLunarDateAndCategory() {
        let entity = makeSUT(today: date(2024, 2, 10)).getInitialState()

        let tet = entity.day(withID: "2024-02-10")
        XCTAssertEqual(tet?.lunarDay, 1)
        XCTAssertEqual(tet?.lunarMonth, 1)
        XCTAssertEqual(tet?.category, .newMoon)
        XCTAssertEqual(tet?.isFastDay, true)

        // Trung Thu 2024: 17/9/2024 = 15 tháng 8 âm.
        let midAutumn = makeSUT(today: date(2024, 9, 1)).getInitialState().day(withID: "2024-09-17")
        XCTAssertEqual(midAutumn?.lunarDay, 15)
        XCTAssertEqual(midAutumn?.lunarMonth, 8)
        XCTAssertEqual(midAutumn?.category, .fullMoon)
    }

    func test_getInitialState_computesHoangDaoFlagForEveryDay() {
        let entity = makeSUT(today: date(2024, 2, 10)).getInitialState()

        // Mỗi ngày phải có cờ Hoàng đạo khớp `ILLunarCalendar.isHoangDao` (tính thật, không tĩnh).
        for month in entity.months {
            for day in month.days {
                let components = calendar.dateComponents([.day, .month, .year], from: day.date)
                let expected = ILLunarCalendar.isHoangDao(
                    solarDay: components.day ?? 1,
                    solarMonth: components.month ?? 1,
                    solarYear: components.year ?? 2000,
                    lunarMonth: day.lunarMonth
                )
                XCTAssertEqual(day.isHoangDao, expected, "day \(day.id)")
            }
        }
    }

    func test_category_forLunarDay_followsFastDayList() {
        XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: 1), .newMoon)
        XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: 15), .fullMoon)
        for day in [8, 14, 18, 23, 30] {
            XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: day), .fastDay, "lunar day \(day)")
        }
        for day in [2, 7, 9, 16, 22, 29] {
            XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: day), .ordinary, "lunar day \(day)")
        }
    }

    func test_category_lastDayOfShortMonth_isFastDay() {
        XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: 29, isLastDayOfShortMonth: true), .fastDay)
        XCTAssertEqual(ILLunarCalendarUseCaseImpl.category(forLunarDay: 29, isLastDayOfShortMonth: false), .ordinary)
    }

    func test_getInitialState_everyLunarMonthEndsOnAFastDay() {
        let sut = makeSUT(today: date(2024, 2, 10))
        let days = sut.getInitialState().months.flatMap(\.days)

        for (index, day) in days.enumerated().dropLast() where days[index + 1].lunarDay == 1 {
            XCTAssertTrue(day.lunarDay == 29 || day.lunarDay == 30, "day \(day.id)")
            XCTAssertTrue(day.isFastDay, "last day of a lunar month must be a fast day: \(day.id)")
        }
    }

    func test_selectDay_updatesSelectionForKnownDay() {
        let sut = makeSUT(today: date(2024, 2, 10))
        let entity = sut.getInitialState()

        let updated = sut.selectDay(id: "2024-03-05", in: entity)

        XCTAssertEqual(updated.selectedDayID, "2024-03-05")
        XCTAssertEqual(updated.todayID, "2024-02-10")
    }

    func test_selectDay_ignoresDayOutsideLoadedMonths() {
        let sut = makeSUT(today: date(2024, 2, 10))
        let entity = sut.getInitialState()

        XCTAssertEqual(sut.selectDay(id: "2030-01-01", in: entity), entity)
    }

    func test_upcomingSpecialDays_returnsNextFastDaysAfterSelectedDayInOrder() {
        let sut = makeSUT(today: date(2024, 2, 10))
        let entity = sut.getInitialState()

        // Sau mùng 1 (10/2): mùng 8 (17/2), rằm... — mùng 8 âm = 17/2, 14 âm = 23/2, rằm = 24/2.
        let upcoming = sut.upcomingSpecialDays(in: entity, limit: 2)

        XCTAssertEqual(upcoming.map(\.id), ["2024-02-17", "2024-02-23"])
        XCTAssertEqual(upcoming.map(\.lunarDay), [8, 14])
    }

    func test_upcomingSpecialDays_excludesSelectedDayItself_andHonorsLimit() {
        let sut = makeSUT(today: date(2024, 2, 10))
        let entity = sut.getInitialState()

        XCTAssertFalse(sut.upcomingSpecialDays(in: entity, limit: 5).contains { $0.id == entity.selectedDayID })
        XCTAssertEqual(sut.upcomingSpecialDays(in: entity, limit: 5).count, 5)
        XCTAssertTrue(sut.upcomingSpecialDays(in: entity, limit: 0).isEmpty)
    }

    func test_upcomingSpecialDays_withUnknownSelection_returnsEmpty() {
        let sut = makeSUT(today: date(2024, 2, 10))
        var entity = sut.getInitialState()
        entity.selectedDayID = "unknown"

        XCTAssertTrue(sut.upcomingSpecialDays(in: entity, limit: 2).isEmpty)
    }
}
