//
//  ILUserBirthProfileRepositoryTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// Exercises `ILUserBirthProfileRepositoryImpl` against a real in-memory Core Data stack.
///
/// The stack is not mocked — `CoreDataStack(inMemory: true)` is a genuine `NSPersistentContainer`
/// with the app's real model, so these tests cover the `UserBirthProfile` model definition and the
/// `ILUserBirthProfileMO` mapping as well as the repository logic. The repository is built the way
/// `DIContainer` builds it — over `ILUserBirthProfileLocalDataSource`.
final class ILUserBirthProfileRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var dataSource: ILUserBirthProfileLocalDataSource!
    private var repository: ILUserBirthProfileRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(
            stack.isLoaded,
            "The in-memory store failed to load. If the model was not found, check that the test "
            + "target is hosted in the app bundle (TEST_HOST / BUNDLE_LOADER)."
        )
        dataSource = ILUserBirthProfileLocalDataSourceImpl(stack: stack)
        repository = ILUserBirthProfileRepositoryImpl(localDataSource: dataSource)
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    private func makeProfile() -> ILUserBirthProfileEntity {
        ILUserBirthProfileEntity(
            solarBirthDate: Date(timeIntervalSince1970: 1_000_000_000),
            lunarYear: 1990,
            canIndex: 6,
            chiIndex: 6,
            element: .tho
        )
    }

    // MARK: - Loading

    func test_loadBirthProfile_whenStoreIsEmpty_returnsNil() async throws {
        let profile = try await repository.loadBirthProfile()
        XCTAssertNil(profile)
    }

    // MARK: - Round trip

    func test_saveBirthProfile_thenLoadBirthProfile_returnsEveryField() async throws {
        let saved = makeProfile()

        try await repository.saveBirthProfile(saved)
        let loaded = try await repository.loadBirthProfile()

        XCTAssertEqual(loaded, saved)
    }

    func test_saveBirthProfile_thenLoad_mapsEachAttributeToItsOwnColumn() async throws {
        let saved = makeProfile()
        try await repository.saveBirthProfile(saved)

        let result = try await repository.loadBirthProfile()
        let loaded = try XCTUnwrap(result)

        XCTAssertEqual(loaded.solarBirthDate, saved.solarBirthDate)
        XCTAssertEqual(loaded.lunarYear, 1990)
        XCTAssertEqual(loaded.canIndex, 6)
        XCTAssertEqual(loaded.chiIndex, 6)
        XCTAssertEqual(loaded.element, .tho)
    }

    // MARK: - Upsert

    func test_saveBirthProfile_twice_keepsOneRowHoldingTheLatestValues() async throws {
        let first = makeProfile()
        let second = ILUserBirthProfileEntity(
            solarBirthDate: Date(timeIntervalSince1970: 2_000_000_000),
            lunarYear: 2001,
            canIndex: 0,
            chiIndex: 0,
            element: .kim
        )

        try await repository.saveBirthProfile(first)
        try await repository.saveBirthProfile(second)

        let loaded = try await repository.loadBirthProfile()
        XCTAssertEqual(loaded, second, "A second save must update the existing row, not add one")

        let rowCount = try await countStoredProfiles()
        XCTAssertEqual(rowCount, 1, "The store must hold exactly one birth profile row")
    }

    // MARK: - Delete

    func test_deleteBirthProfile_thenLoadBirthProfile_returnsNil() async throws {
        try await repository.saveBirthProfile(makeProfile())

        try await repository.deleteBirthProfile()
        let loaded = try await repository.loadBirthProfile()

        XCTAssertNil(loaded)
    }

    func test_deleteBirthProfile_whenStoreIsEmpty_doesNotThrow() async throws {
        try await repository.deleteBirthProfile()

        let loaded = try await repository.loadBirthProfile()
        XCTAssertNil(loaded)
    }

    // MARK: - Helpers

    private func countStoredProfiles() async throws -> Int {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILUserBirthProfileMO>(entityName: ILUserBirthProfileMO.entityName)
            return try context.count(for: request)
        }
    }
}
