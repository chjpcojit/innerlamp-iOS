//
//  ILSanghaUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSanghaUseCaseTests: XCTestCase {

    private var storage: InMemoryUserDefaultsService!
    private var sut: ILSanghaUseCaseImpl!

    override func setUp() {
        super.setUp()
        storage = InMemoryUserDefaultsService()
        sut = ILSanghaUseCaseImpl(userDefaultsService: storage, now: { Date(timeIntervalSince1970: 1_790_000_000) })
    }

    override func tearDown() {
        sut = nil
        storage = nil
        super.tearDown()
    }

    func test_loadMyTemple_defaultsToTuQuangBeforeAnyChoice() {
        XCTAssertEqual(sut.loadMyTemple()?.temple.id, ILSanghaUseCaseImpl.defaultTempleID)
    }

    func test_loadMyTemple_withEmptyStoredID_fallsBackToDefault() {
        sut.selectMyTemple(id: "")
        XCTAssertEqual(sut.loadMyTemple()?.temple.id, ILSanghaUseCaseImpl.defaultTempleID)
    }

    func test_selectMyTemple_thenLoadMyTemple_returnsThatTemple() {
        sut.selectMyTemple(id: "temple-xaloi")
        XCTAssertEqual(sut.loadMyTemple()?.temple.id, "temple-xaloi")
    }

    func test_selectMyTemple_fromCatalog_loadsFromSnapshot() {
        sut.selectMyTemple(ILTempleFinderUseCaseTests.makeTemple(id: "temple_north_001", name: "Chùa Một Cột", address: "Ba Đình, Hà Nội"))

        let temple = sut.loadMyTemple()?.temple
        XCTAssertEqual(temple?.id, "temple_north_001")
        XCTAssertEqual(temple?.name, "Chùa Một Cột")
        XCTAssertEqual(temple?.address, "Ba Đình, Hà Nội")
        XCTAssertEqual(temple?.operatingHours, "")
    }

    func test_selectMyTemple_fromCatalog_thenMockTemple_dropsTheCatalogTemple() {
        sut.selectMyTemple(ILTempleFinderUseCaseTests.makeTemple(id: "temple_north_001", name: "Chùa Một Cột", address: "Hà Nội"))
        sut.selectMyTemple(id: "temple-xaloi")

        XCTAssertEqual(sut.loadMyTemple()?.temple.id, "temple-xaloi")
    }

    func test_loadMyTemple_withUnknownStoredID_returnsNil() {
        sut.selectMyTemple(id: "does-not-exist")
        XCTAssertNil(sut.loadMyTemple())
    }

    func test_loadChooser_listsNearbyTemplesSortedByDistance() {
        let distances = sut.loadChooser().nearbyTemples.map(\.distanceKm)
        XCTAssertFalse(distances.isEmpty)
        XCTAssertEqual(distances, distances.sorted())
    }

    func test_loadUpcomingDays_respectsLimit() {
        XCTAssertEqual(sut.loadUpcomingDays(limit: 2).count, 2)
        XCTAssertEqual(sut.loadUpcomingDays(limit: 10).count, 4)
    }
}

private final class InMemoryUserDefaultsService: UserDefaultsService {
    private var store: [String: Data] = [:]

    func save<T: Codable>(key: String, value: T) { store[key] = try? JSONEncoder().encode(value) }
    func load<T: Codable>(key: String, type: T.Type) -> T? {
        store[key].flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    func remove(key: String) { store[key] = nil }
    func exists(key: String) -> Bool { store[key] != nil }
}
