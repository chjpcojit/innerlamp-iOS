//
//  ILMemorialAccountScopeTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// G1 item 2: the memorial cache is account-scoped. No read may return another account's rows.
final class ILMemorialAccountScopeTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    private var stack: CoreDataStack!
    private var identity: ILFixedAccountIdentityProvider!
    private var sut: ILMemorialLocalDataSource!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        identity = ILFixedAccountIdentityProvider(accountID: "account-a")
        sut = ILMemorialLocalDataSourceImpl(stack: stack, accountIdentity: identity)
    }

    override func tearDown() {
        sut = nil
        identity = nil
        stack = nil
        super.tearDown()
    }

    func test_readsAndReplaceAll_areScopedToTheCurrentAccount() async throws {
        try await sut.replaceAll([Factory.entry(id: "a-1", name: "Của A")])

        identity.accountID = "account-b"
        let bBefore = try await sut.fetchAll()
        XCTAssertTrue(bBefore.isEmpty, "B must not see A's cache")

        try await sut.replaceAll([Factory.entry(id: "b-1", name: "Của B")])
        let bRows = try await sut.fetchAll()
        XCTAssertEqual(bRows.map(\.id), ["b-1"])

        identity.accountID = "account-a"
        let aRows = try await sut.fetchAll()
        XCTAssertEqual(aRows.map(\.id), ["a-1"], "B's replaceAll must not delete A's rows")
    }

    func test_noAccount_throwsInsteadOfReturningRows() async throws {
        try await sut.replaceAll([Factory.entry(id: "a-1")])
        identity.accountID = nil

        do {
            _ = try await sut.fetchAll()
            XCTFail("Expected noAccount")
        } catch {
            guard case ILMemorialCacheError.noAccount = error else {
                return XCTFail("Got \(error)")
            }
        }
    }

    func test_legacyRowsWithEmptyOwner_arePurged() async throws {
        try await stack.performBackgroundTask { context in
            let row = try XCTUnwrap(
                NSEntityDescription.insertNewObject(
                    forEntityName: ILMemorialMO.entityName, into: context
                ) as? ILMemorialMO
            )
            row.id = "legacy"
            row.ownerAccountID = ""
            row.name = "Legacy"
            row.relationship = ILMemorialRelationship.father.rawValue
            row.calendarKind = ILMemorialCalendarKind.solar.rawValue
            row.day = 1
            row.month = 1
            row.deathYear = 0
            row.deathLeapMonth = false
            row.note = ""
            row.reminderLeadDays = -1
            row.reminderHour = 7
            row.reminderMinute = 0
        }

        let rows = try await sut.fetchAll()
        XCTAssertTrue(rows.isEmpty)

        let remaining = try await stack.performBackgroundTask { context in
            try context.fetch(NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName))
        }
        XCTAssertTrue(remaining.isEmpty, "A row with no owner must not stay on disk")
    }
}
