//
//  ILMemorialMapperTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILMemorialMapperTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    func test_toRequest_unknownYear_sendsDayMonthAndCalendar() throws {
        let request = try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .lunar, day: 30, month: 12, deathYear: nil))

        XCTAssertNil(request.deathDate)
        XCTAssertEqual(request.deathDay, 30)
        XCTAssertEqual(request.deathMonth, 12)
        XCTAssertEqual(request.deathLeapMonth, false)
        XCTAssertEqual(request.deathCalendar, "lunar")
    }

    func test_toRequest_knownSolarYear_sendsSolarDeathDateOnly() throws {
        let request = try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .solar, day: 5, month: 3, deathYear: 2019))

        XCTAssertEqual(request.deathDate, "2019-03-05")
        XCTAssertNil(request.deathDay)
        XCTAssertNil(request.deathMonth)
        XCTAssertNil(request.deathLeapMonth)
    }

    func test_toRequest_knownLunarYear_convertsToSolar() throws {
        // Lunar 1/1/2024 (Tết Giáp Thìn) = 2024-02-10.
        let request = try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .lunar, day: 1, month: 1, deathYear: 2024))

        XCTAssertEqual(request.deathDate, "2024-02-10")
        XCTAssertEqual(request.deathCalendar, "lunar")
    }

    func test_toRequest_nonexistentSolarDate_throws() {
        XCTAssertThrowsError(try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .solar, day: 29, month: 2, deathYear: 2023)))
        XCTAssertThrowsError(try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .solar, day: 31, month: 4, deathYear: 2020)))
    }

    func test_toRequest_leapDayWithoutYear_isAllowed() throws {
        XCTAssertNoThrow(try ILMemorialMapper.toRequest(Factory.entry(calendarKind: .solar, day: 29, month: 2, deathYear: nil)))
    }

    func test_toRequest_reminderOff_forcesOSReminderOff() throws {
        let request = try ILMemorialMapper.toRequest(Factory.entry(reminder: nil, syncToReminders: true))

        XCTAssertNil(request.reminder)
        XCTAssertFalse(request.addToOsReminder)
    }

    func test_toRequest_reminderOn_formatsTime() throws {
        let request = try ILMemorialMapper.toRequest(
            Factory.entry(reminder: ILMemorialReminder(leadDays: 3, hour: 6, minute: 5), syncToReminders: true)
        )

        XCTAssertEqual(request.reminder, ILMemorialReminderRequestDTO(daysBefore: 3, time: "06:05"))
        XCTAssertTrue(request.addToOsReminder)
    }

    func test_toRequest_trimsNote() throws {
        XCTAssertEqual(try ILMemorialMapper.toRequest(Factory.entry(note: "  mâm chay \n")).note, "mâm chay")
    }

    func test_toRequest_everyRelationship_hasDistinctWireValue() throws {
        let wires = try ILMemorialRelationship.allCases.map {
            try ILMemorialMapper.toRequest(Factory.entry(relationship: $0)).relationship
        }

        XCTAssertEqual(Set(wires).count, ILMemorialRelationship.allCases.count)
        XCTAssertTrue(wires.contains("GRANDFATHER_PATERNAL"))
    }

    func test_roundTrip_lunarWithYear_survivesSolarConversion() throws {
        let entry = Factory.entry(id: "9", calendarKind: .lunar, day: 15, month: 7, deathYear: 2019)
        let request = try ILMemorialMapper.toRequest(entry)
        let dto = ILMemorialDTO(
            id: 9, fullName: entry.name, relationship: request.relationship, deathDate: request.deathDate,
            deathCalendar: request.deathCalendar, deathDay: nil, deathMonth: nil, deathLeapMonth: nil,
            note: nil, reminder: ILMemorialReminderDTO(daysBefore: 1, time: "07:00"), addToOsReminder: true
        )

        let back = ILMemorialMapper.toDomain(dto)

        XCTAssertEqual(back.calendarKind, .lunar)
        XCTAssertEqual([back.day, back.month, back.deathYear ?? 0], [15, 7, 2019])
        XCTAssertEqual(back.id, "9")
    }
}
