//
//  ILLightLampUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILLightLampUseCaseTests: XCTestCase {

    private typealias Factory = ILLightLampTestFactory

    private var repository: FakeILLampRepository!
    private var sut: ILLightLampUseCaseImpl!
    private let now = Factory.date(2026, 10, 11)

    override func setUp() {
        super.setUp()
        repository = FakeILLampRepository()
        sut = ILLightLampUseCaseImpl(repository: repository, makeID: { "fixed-id" })
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - light

    func test_light_savesTrimmedLampAtNow() async throws {
        let draft = ILLampDraft(
            kind: .lotus, intention: .gratitude, target: "  Mẹ  ", vow: " Mẹ luôn khỏe \n", durationDays: 21
        )

        let lamp = try await sut.light(draft, now: now)

        XCTAssertEqual(lamp.id, "fixed-id")
        XCTAssertEqual(lamp.kind, .lotus)
        XCTAssertEqual(lamp.intention, .gratitude)
        XCTAssertEqual(lamp.target, "Mẹ")
        XCTAssertEqual(lamp.vow, "Mẹ luôn khỏe")
        XCTAssertEqual(lamp.durationDays, 21)
        XCTAssertEqual(lamp.litAt, now)
        XCTAssertEqual(repository.stored, [lamp])
    }

    func test_light_whitespaceOnlyTarget_becomesEmptyMeaningAllBeings() async throws {
        let lamp = try await sut.light(ILLampDraft(target: "   "), now: now)

        XCTAssertEqual(lamp.target, "")
    }

    func test_light_saveFailure_propagatesAndStoresNothing() async {
        repository.saveError = ILLampError.saveFailed(ILLightLampTestError())

        do {
            _ = try await sut.light(ILLampDraft(), now: now)
            XCTFail("expected a throw")
        } catch {
            XCTAssertTrue(repository.stored.isEmpty)
        }
    }

    // MARK: - loadActiveLamps

    func test_loadActiveLamps_dropsElapsedLamps() async throws {
        let litThreeDaysAgo = Factory.lamp(id: "a", durationDays: 7, litAt: Factory.date(2026, 10, 8))
        let litEightDaysAgo = Factory.lamp(id: "b", durationDays: 7, litAt: Factory.date(2026, 10, 3))
        repository.stored = [litThreeDaysAgo, litEightDaysAgo]

        let active = try await sut.loadActiveLamps(now: now)

        XCTAssertEqual(active.map(\.id), ["a"])
    }

    func test_loadActiveLamps_sortsNewestFirst() async throws {
        repository.stored = [
            Factory.lamp(id: "old", litAt: Factory.date(2026, 10, 9)),
            Factory.lamp(id: "new", litAt: Factory.date(2026, 10, 11)),
            Factory.lamp(id: "mid", litAt: Factory.date(2026, 10, 10))
        ]

        let active = try await sut.loadActiveLamps(now: now)

        XCTAssertEqual(active.map(\.id), ["new", "mid", "old"])
    }

    // MARK: - ILLampEntity.daysLeft

    func test_daysLeft_litToday_isFullDuration() {
        let lamp = Factory.lamp(durationDays: 7, litAt: now)

        XCTAssertEqual(lamp.daysLeft(now: now, calendar: Factory.calendar), 7)
    }

    func test_daysLeft_litThreeDaysAgoForSeven_isFour() {
        let lamp = Factory.lamp(durationDays: 7, litAt: Factory.date(2026, 10, 8))

        XCTAssertEqual(lamp.daysLeft(now: now, calendar: Factory.calendar), 4)
    }

    func test_daysLeft_litSevenDaysAgoForSeven_isGoneOut() {
        let lamp = Factory.lamp(durationDays: 7, litAt: Factory.date(2026, 10, 4))

        XCTAssertFalse(lamp.isActive(now: now, calendar: Factory.calendar))
    }

    func test_daysLeft_oneDayLampLitToday_isOnTheLastDay() {
        let lamp = Factory.lamp(durationDays: 1, litAt: now)

        XCTAssertEqual(lamp.daysLeft(now: now, calendar: Factory.calendar), 1)
    }
}
