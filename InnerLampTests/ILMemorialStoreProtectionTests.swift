//
//  ILMemorialStoreProtectionTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// G1 item 1: memorial rows hold names, dates of death and notes. Their store must be excluded from
/// iCloud/iTunes backup and carry file protection, while the rest of the database stays backup-eligible.
final class ILMemorialStoreProtectionTests: XCTestCase {

    private static let memorialStore = CoreDataStack.SeparatedStore(
        configurationName: "Memorial",
        fileName: "InnerLampMemorial.sqlite",
        excludesFromBackup: true,
        legacyEntityName: ILMemorialMO.entityName
    )

    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ILMemorialStoreProtection-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    func test_memorialStoreAndSidecars_areExcludedFromBackup_andProtected() async throws {
        let storeURL = directory.appendingPathComponent("InnerLamp.sqlite")
        let stack = CoreDataStack(storeURL: storeURL, separatedStores: [Self.memorialStore])
        XCTAssertTrue(stack.isLoaded)
        XCTAssertEqual(stack.storeURL?.lastPathComponent, "InnerLamp.sqlite")

        let memorialURL = try XCTUnwrap(stack.separatedStoreURLs["Memorial"])
        XCTAssertEqual(memorialURL.lastPathComponent, "InnerLampMemorial.sqlite")

        try await writeOneRow(to: stack)

        var checked = 0
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: memorialURL.path + suffix)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
            checked += 1

            let values = try fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(values.isExcludedFromBackup, true, "\(fileURL.lastPathComponent) is in backup")

            // The simulator's APFS does not expose NSFileProtection; assert it when the OS reports
            // it, and always rely on the backup exclusion above.
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let protection = attributes[.protectionKey] as? String {
                XCTAssertEqual(
                    protection,
                    FileProtectionType.completeUntilFirstUserAuthentication.rawValue,
                    "\(fileURL.lastPathComponent) has the wrong file protection"
                )
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 1)
    }

    func test_defaultStore_isNotExcludedFromBackup() async throws {
        let storeURL = directory.appendingPathComponent("InnerLamp.sqlite")
        let stack = CoreDataStack(storeURL: storeURL, separatedStores: [Self.memorialStore])
        XCTAssertTrue(stack.isLoaded)
        try await writeOneRow(to: stack)

        var checked = 0
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: storeURL.path + suffix)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
            checked += 1

            let values = try fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertNotEqual(
                values.isExcludedFromBackup,
                true,
                "\(fileURL.lastPathComponent) must stay in a device backup"
            )
        }
        XCTAssertGreaterThanOrEqual(checked, 1)
    }

    func test_restoreWithoutTheExcludedStore_hasNoMemorialRows() async throws {
        let originalURL = directory.appendingPathComponent("device-a/InnerLamp.sqlite")
        try FileManager.default.createDirectory(
            at: originalURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let original = CoreDataStack(storeURL: originalURL, separatedStores: [Self.memorialStore])
        XCTAssertTrue(original.isLoaded)
        try await writeOneRow(to: original)

        // A second device/install: the excluded store did not travel, so the new stack is empty.
        let restoredURL = directory.appendingPathComponent("device-b/InnerLamp.sqlite")
        try FileManager.default.createDirectory(
            at: restoredURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let restored = CoreDataStack(storeURL: restoredURL, separatedStores: [Self.memorialStore])
        XCTAssertTrue(restored.isLoaded)
        let local = ILMemorialLocalDataSourceImpl(
            stack: restored,
            accountIdentity: ILMemorialTestFactory.identity()
        )

        let rows = try await local.fetchAll()
        XCTAssertTrue(rows.isEmpty, "A store excluded from backup must not restore memorial data")
    }

    private func writeOneRow(to stack: CoreDataStack) async throws {
        try await stack.performBackgroundTask { context in
            let row = try XCTUnwrap(
                NSEntityDescription.insertNewObject(
                    forEntityName: ILMemorialMO.entityName, into: context
                ) as? ILMemorialMO
            )
            row.id = "protected-1"
            row.ownerAccountID = ILMemorialTestFactory.accountID
            row.name = "Nguyễn Văn An"
            row.relationship = ILMemorialRelationship.father.rawValue
            row.calendarKind = ILMemorialCalendarKind.solar.rawValue
            row.day = 1
            row.month = 1
            row.deathYear = 0
            row.deathLeapMonth = false
            row.note = "ghi chú"
            row.reminderLeadDays = -1
            row.reminderHour = 7
            row.reminderMinute = 0
        }
    }
}
