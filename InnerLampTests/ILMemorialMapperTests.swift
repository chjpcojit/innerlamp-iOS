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

    func test_toRequest_reminderOff_sendsNilReminder() throws {
        let request = try ILMemorialMapper.toRequest(Factory.entry(reminder: nil))

        XCTAssertNil(request.reminder)
    }

    func test_toRequest_reminderOn_formatsTime() throws {
        let request = try ILMemorialMapper.toRequest(
            Factory.entry(reminder: ILMemorialReminder(leadDays: 3, hour: 6, minute: 5))
        )

        XCTAssertEqual(request.reminder, ILMemorialReminderRequestDTO(daysBefore: 3, time: "06:05"))
    }

    func test_toRequest_neverEncodesRemovedFields() throws {
        let request = try ILMemorialMapper.toRequest(Factory.entry(reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)))
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )

        XCTAssertNil(json["add_to_os_reminder"])
        let reminder = try XCTUnwrap(json["reminder"] as? [String: Any])
        XCTAssertNil(reminder["timezone"])
        XCTAssertEqual(Set(reminder.keys), ["days_before", "time"])
    }

    func test_toRequest_lunarLeapMonth_isSentOnlyWithoutYear() throws {
        let yearless = try ILMemorialMapper.toRequest(
            Factory.entry(calendarKind: .lunar, day: 15, month: 7, deathYear: nil, deathLeapMonth: true)
        )
        XCTAssertEqual(yearless.deathLeapMonth, true)

        let solar = try ILMemorialMapper.toRequest(
            Factory.entry(calendarKind: .solar, day: 15, month: 7, deathYear: nil, deathLeapMonth: true)
        )
        XCTAssertNil(solar.deathLeapMonth, "Solar dates never carry the lunar leap flag")
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
            note: nil, photoUrl: nil, reminder: ILMemorialReminderDTO(daysBefore: 1, time: "07:00")
        )

        let back = try ILMemorialMapper.toDomain(dto)

        XCTAssertEqual(back.calendarKind, .lunar)
        XCTAssertEqual([back.day, back.month, back.deathYear ?? 0], [15, 7, 2019])
        XCTAssertEqual(back.id, "9")
    }

    // MARK: - Response decoding (contract 2026-11-16)

    private static func dto(
        relationship: String = "FATHER",
        deathDate: String? = nil,
        deathCalendar: String = "lunar",
        deathDay: Int? = 15,
        deathMonth: Int? = 7,
        deathLeapMonth: Bool? = false,
        photoUrl: String? = nil
    ) -> ILMemorialDTO {
        ILMemorialDTO(
            id: 7, fullName: "Nguyễn Văn An", relationship: relationship, deathDate: deathDate,
            deathCalendar: deathCalendar, deathDay: deathDay, deathMonth: deathMonth,
            deathLeapMonth: deathLeapMonth, note: nil, photoUrl: photoUrl,
            reminder: ILMemorialReminderDTO(daysBefore: 1, time: "07:00")
        )
    }

    func test_toDomain_keepsYearlessLunarLeapFlag() throws {
        let entity = try ILMemorialMapper.toDomain(Self.dto(deathLeapMonth: true))

        XCTAssertEqual(entity.calendarKind, .lunar)
        XCTAssertTrue(entity.deathLeapMonth)
        XCTAssertNil(entity.deathYear)
    }

    func test_toDomain_unknownRelationship_failsInsteadOfOther() {
        XCTAssertThrowsError(try ILMemorialMapper.toDomain(Self.dto(relationship: "GREAT_AUNT"))) { error in
            XCTAssertEqual(error as? ILMemorialMapper.UndecodableError, ILMemorialMapper.UndecodableError(field: "relationship"))
        }
    }

    func test_toDomain_photoURL_isSessionState() throws {
        let entity = try ILMemorialMapper.toDomain(Self.dto(photoUrl: "https://example.com/p.jpg?sig=1"))

        XCTAssertEqual(entity.photoURL?.absoluteString, "https://example.com/p.jpg?sig=1")
    }

    func test_decodeList_worksForV1AndV4ReminderShapes() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // swiftlint:disable line_length
        let v1 = #"{"success":true,"data":{"items":[{"id":1,"full_name":"A","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":1,"death_month":1,"death_leap_month":false,"note":null,"photo_url":null,"reminder":{"days_before":1,"time":"07:00","timezone":"Asia/Ho_Chi_Minh"},"add_to_os_reminder":true,"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}],"total":1}}"#
        let v4 = #"{"success":true,"data":{"items":[{"id":1,"full_name":"A","relationship":"FATHER","death_date":null,"death_calendar":"lunar","death_day":1,"death_month":1,"death_leap_month":false,"note":null,"photo_url":null,"reminder":{"days_before":1,"time":"07:00"},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}],"total":1}}"#

        // swiftlint:enable line_length

        for json in [v1, v4] {
            let envelope = try decoder.decode(APIEnvelope<ILMemorialListDTO>.self, from: Data(json.utf8))
            let dto = try XCTUnwrap(envelope.data?.items.first)
            XCTAssertEqual(dto.reminder?.time, "07:00")
        }
    }

    // MARK: - Strict date decoding (P1 fix)

    private func assertUndecodable(
        _ field: String,
        _ body: () throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            XCTAssertEqual(
                error as? ILMemorialMapper.UndecodableError,
                ILMemorialMapper.UndecodableError(field: field),
                file: file,
                line: line
            )
        }
    }

    func test_toDomain_garbageDeathDate_throwsDeathDate() {
        assertUndecodable("death_date") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathDate: "not-a-date", deathDay: nil, deathMonth: nil))
        }
    }

    func test_toDomain_impossibleDeathDate_throwsDeathDate() {
        assertUndecodable("death_date") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathDate: "2026-02-31", deathDay: nil, deathMonth: nil))
        }
    }

    func test_toDomain_leapDayInCommonYear_throwsDeathDate() {
        assertUndecodable("death_date") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathDate: "2023-02-29", deathDay: nil, deathMonth: nil))
        }
    }

    func test_toDomain_leapDayInLeapYear_isAccepted() throws {
        let entity = try ILMemorialMapper.toDomain(
            Self.dto(deathDate: "2024-02-29", deathDay: nil, deathMonth: nil)
        )

        XCTAssertEqual([entity.day, entity.month, entity.deathYear ?? 0], [29, 2, 2024])
    }

    func test_toDomain_missingDeathDay_throwsDeathDay() {
        assertUndecodable("death_day") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathDay: nil))
        }
    }

    func test_toDomain_missingDeathMonth_throwsDeathMonth() {
        assertUndecodable("death_month") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathMonth: nil))
        }
    }

    func test_toDomain_solar31February_throwsDeathDay() {
        assertUndecodable("death_day") {
            _ = try ILMemorialMapper.toDomain(Self.dto(deathDay: 31, deathMonth: 2))
        }
    }

    func test_toDomain_solar29FebruaryWithoutYear_isAccepted() throws {
        let entity = try ILMemorialMapper.toDomain(Self.dto(deathDay: 29, deathMonth: 2))

        XCTAssertEqual([entity.day, entity.month], [29, 2])
        XCTAssertNil(entity.deathYear)
    }

    func test_toDomain_lunarDay30WithoutYear_isAccepted() throws {
        let entity = try ILMemorialMapper.toDomain(
            Self.dto(deathCalendar: "lunar", deathDay: 30, deathMonth: 7)
        )

        XCTAssertEqual([entity.day, entity.month], [30, 7])
    }
}
