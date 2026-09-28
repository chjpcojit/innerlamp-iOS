//
//  ILBuddhistEventRepositoryTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// Exercises `ILBuddhistEventRepositoryImpl` against a real in-memory Core Data stack.
///
/// The stack is not mocked — `CoreDataStack(inMemory: true)` is a genuine `NSPersistentContainer`
/// with the app's real model, so these tests cover the model definition, the seeding, and the
/// `ILBuddhistEventTemplateMO` mapping as well as the repository logic. The repository is built the
/// way `DIContainer` builds it — over `ILBuddhistEventLocalDataSource`.
final class ILBuddhistEventRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var dataSource: ILBuddhistEventLocalDataSource!
    private var repository: ILBuddhistEventRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(
            stack.isLoaded,
            "The in-memory store failed to load. If the model was not found, check that the test "
            + "target is hosted in the app bundle (TEST_HOST / BUNDLE_LOADER)."
        )
        dataSource = ILBuddhistEventLocalDataSourceImpl(stack: stack)
        repository = ILBuddhistEventRepositoryImpl(localDataSource: dataSource)
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Seeding

    func test_loadTemplates_seedsStoreOnFirstRead() async throws {
        let templates = try await repository.loadTemplates()

        XCTAssertFalse(templates.isEmpty, "The store must be seeded with the Buddhist holiday catalog")
    }

    func test_loadTemplates_seedingIsIdempotent() async throws {
        let first = try await repository.loadTemplates()
        let second = try await repository.loadTemplates()
        let third = try await repository.loadTemplates()

        XCTAssertEqual(first.count, second.count)
        XCTAssertEqual(second.count, third.count)
    }

    func test_loadTemplates_seedsTraditionalFestivalAndViaDays() async throws {
        let templates = try await repository.loadTemplates()
        let ids = Set(templates.map(\.id))

        // Traditional Vietnamese festival days (folk).
        for expected in ["han-thuc", "doan-ngo", "trung-thu", "trung-cuu", "ha-nguyen", "ong-cong-ong-tao"] {
            XCTAssertTrue(ids.contains(expected), "Seed must include \(expected)")
        }

        // Vía / commemoration days from the design handoff.
        for expected in ["di-lac", "thich-ca-xuat-gia", "pho-hien", "van-thu", "an-cu-kiet-ha",
                         "dai-the-chi", "nhien-dang", "duoc-su", "dat-ma"] {
            XCTAssertTrue(ids.contains(expected), "Seed must include \(expected)")
        }
    }

    // MARK: - Mapping

    func test_loadTemplates_mapsEveryFieldForKnownSeed() async throws {
        let templates = try await repository.loadTemplates()

        let phatDan = try XCTUnwrap(templates.first { $0.id == "phat-dan" })
        XCTAssertEqual(phatDan.title, "Đại lễ Phật Đản")
        XCTAssertEqual(phatDan.lunarDay, 15)
        XCTAssertEqual(phatDan.lunarMonth, 4)
        XCTAssertEqual(phatDan.tradition, .universal)
        XCTAssertFalse(phatDan.isLeapMonthEligible)
        XCTAssertFalse(phatDan.eventDescription.isEmpty)
    }

    func test_loadTemplates_coversAllThreeTraditions() async throws {
        let templates = try await repository.loadTemplates()

        let traditions = Set(templates.map(\.tradition))
        XCTAssertTrue(traditions.contains(.mahayana))
        XCTAssertTrue(traditions.contains(.theravada))
        XCTAssertTrue(traditions.contains(.universal))
    }

    func test_loadTemplates_traditionRoundTripsThroughRawValue() async throws {
        let templates = try await repository.loadTemplates()

        let vuLan = try XCTUnwrap(templates.first { $0.id == "vu-lan" })
        XCTAssertEqual(vuLan.tradition, .mahayana)

        let kathina = try XCTUnwrap(templates.first { $0.id == "kathina" })
        XCTAssertEqual(kathina.tradition, .theravada)
    }

    // MARK: - Helpers

    /// Counts rows through the stack rather than the repository, so a bug that duplicated rows
    /// would still be visible here.
    private func countStoredTemplates() async throws -> Int {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILBuddhistEventTemplateMO>(entityName: ILBuddhistEventTemplateMO.entityName)
            return try context.count(for: request)
        }
    }

    func test_seeding_leavesExactlyOneRowPerTemplate() async throws {
        _ = try await repository.loadTemplates()
        _ = try await repository.loadTemplates()

        let rowCount = try await countStoredTemplates()
        let templateCount = try await repository.loadTemplates().count
        XCTAssertEqual(rowCount, templateCount, "Repeated reads must not duplicate seeded rows")
    }
}
