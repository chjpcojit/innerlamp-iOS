//
//  ILUserRepositoryTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// Exercises `ILUserRepositoryImpl` against a real in-memory Core Data stack.
///
/// The stack is not mocked. `CoreDataStack(inMemory: true)` is a genuine `NSPersistentContainer`
/// with the app's real model, so these tests cover the model definition and the `ILUserMO`
/// mapping as well as the repository logic — a hand-rolled mock would cover only the last of the
/// three.
///
/// The repository is built the way `DIContainer` builds it — over `ILUserLocalDataSource` — so the
/// path exercised here is the one the app runs, not a shortcut that skips a layer.
final class ILUserRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var dataSource: ILUserLocalDataSource!
    private var repository: ILUserRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(
            stack.isLoaded,
            "The in-memory store failed to load. If the model was not found, check that the test "
            + "target is hosted in the app bundle (TEST_HOST / BUNDLE_LOADER)."
        )
        dataSource = ILUserLocalDataSourceImpl(stack: stack)
        repository = ILUserRepositoryImpl(localDataSource: dataSource)
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Loading

    func test_loadUser_whenStoreIsEmpty_returnsNil() async throws {
        let user = try await repository.loadUser()

        XCTAssertNil(user)
    }

    // MARK: - Round trip

    func test_saveUser_thenLoadUser_returnsEveryField() async throws {
        let saved = ILUserEntity(
            id: 42,
            email: "an@example.com",
            phoneNumber: "+84912345678",
            dharmaName: "Diệu Tâm",
            ordinationPlace: "Chùa Linh Ứng"
        )

        try await repository.saveUser(saved)
        let loaded = try await repository.loadUser()

        XCTAssertEqual(loaded, saved)
    }

    /// Pins the individual fields as well as the whole value. `Equatable` would already catch a
    /// swapped pair by passing, so the per-field assertions state which field broke.
    func test_saveUser_thenLoadUser_mapsEachAttributeToItsOwnColumn() async throws {
        let saved = ILUserEntity(
            id: 7,
            email: "b@example.com",
            phoneNumber: "+84900000001",
            dharmaName: "Tịnh An",
            ordinationPlace: "Chùa Ba Vàng"
        )

        try await repository.saveUser(saved)
        let result = try await repository.loadUser()
        let loaded = try XCTUnwrap(result)

        XCTAssertEqual(loaded.id, 7)
        XCTAssertEqual(loaded.email, "b@example.com")
        XCTAssertEqual(loaded.phoneNumber, "+84900000001")
        XCTAssertEqual(loaded.dharmaName, "Tịnh An")
        XCTAssertEqual(loaded.ordinationPlace, "Chùa Ba Vàng")
    }

    // MARK: - Upsert

    func test_saveUser_twice_keepsOneRowHoldingTheLatestValues() async throws {
        let first = ILUserEntity(
            id: 1,
            email: "first@example.com",
            phoneNumber: "+84911111111",
            dharmaName: "Minh Đăng",
            ordinationPlace: "Chùa Một"
        )
        let second = ILUserEntity(
            id: 2,
            email: "second@example.com",
            phoneNumber: "+84922222222",
            dharmaName: "Huệ Nhẫn",
            ordinationPlace: "Chùa Hai"
        )

        try await repository.saveUser(first)
        try await repository.saveUser(second)

        let loaded = try await repository.loadUser()
        XCTAssertEqual(loaded, second, "A second save must update the existing row, not add one")

        let rowCount = try await countStoredUsers()
        XCTAssertEqual(rowCount, 1, "The store must hold exactly one user row")
    }

    // MARK: - Delete

    func test_deleteUser_thenLoadUser_returnsNil() async throws {
        try await repository.saveUser(ILUserEntity(id: 9, email: "c@example.com"))

        try await repository.deleteUser()
        let loaded = try await repository.loadUser()

        XCTAssertNil(loaded)
    }

    func test_deleteUser_whenStoreIsEmpty_doesNotThrow() async throws {
        try await repository.deleteUser()

        let loaded = try await repository.loadUser()
        XCTAssertNil(loaded)
    }

    // MARK: - Helpers

    /// Counts rows through the stack rather than the repository, so a bug that hid a duplicate row
    /// from `loadUser()` would still be visible here.
    private func countStoredUsers() async throws -> Int {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILUserMO>(entityName: ILUserMO.entityName)
            return try context.count(for: request)
        }
    }
}
