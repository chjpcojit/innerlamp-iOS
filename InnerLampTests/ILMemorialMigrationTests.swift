//
//  ILMemorialMigrationTests.swift
//  InnerLampTests
//

import CoreData
import SQLite3
import XCTest
@testable import InnerLamp

/// B2 from the task breakdown: the new model version must open a store written by the build that
/// is on main (`InnerLamp 5`) with inferred lightweight migration — no custom mapping.
final class ILMemorialMigrationTests: XCTestCase {

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
            .appendingPathComponent("ILMemorialMigration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    func test_model5Store_opensWithModel7_andKeepsMemorialRows() throws {
        let storeURL = directory.appendingPathComponent("InnerLamp.sqlite")
        try writeModel5Store(at: storeURL)

        let stack = CoreDataStack(storeURL: storeURL, separatedStores: [Self.memorialStore])
        XCTAssertTrue(stack.isLoaded, "Lightweight migration from InnerLamp 5 to InnerLamp 7 failed")

        let memorialURL = try XCTUnwrap(stack.separatedStoreURLs["Memorial"])
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: memorialURL.path),
            "The memorial store was not created next to the default one"
        )

        let rows = try waitForRows(stack)
        XCTAssertEqual(rows.count, 1, "Legacy rows move from the single store into the memorial store")
        XCTAssertEqual(rows.first?["id"] as? String, "legacy-1")
        XCTAssertEqual(rows.first?["name"] as? String, "Cụ Ông")
        XCTAssertEqual(rows.first?["deathLeapMonth"] as? Bool, false)
        XCTAssertEqual(rows.first?["ownerAccountID"] as? String, "", "Migrated rows have no owner until purged")
    }

    /// I-1 from the security review: deleting the legacy row is not enough, because its name and
    /// note survive in the free pages of the main store, which is backup-eligible after the split.
    /// The move must compact that file before it counts as done.
    func test_legacySplit_vacuumsMainStore_beforeMarkingMigrationDone() throws {
        let storeURL = directory.appendingPathComponent("InnerLamp.sqlite")
        let name = "ZZLegacyName7f3a9c"
        let note = "ZZLegacyNote4b81de"
        try writeModel5Store(at: storeURL, name: name, note: note)

        let before = try Data(contentsOf: storeURL)
        XCTAssertNotNil(before.range(of: Data(name.utf8)), "the fixture row is not in the pre-split store")
        XCTAssertEqual(try XCTUnwrap(countRows("ZMEMORIAL", at: storeURL)), 1)

        let suiteName = "ILMemorialLegacySplit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let stack = CoreDataStack(storeURL: storeURL, separatedStores: [Self.memorialStore], defaults: defaults)
        XCTAssertTrue(stack.isLoaded)
        XCTAssertTrue(
            defaults.bool(forKey: CoreDataStackLegacySplit.markerKey(for: "Memorial")),
            "the split is only marked done after VACUUM, checkpoint and an empty re-read"
        )

        // (a) the row moved into the store the entity is now routed to
        let rows = try waitForRows(stack)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?["name"] as? String, name)
        XCTAssertEqual(rows.first?["note"] as? String, note)

        // (b) the main store holds no memorial row any more
        XCTAssertEqual(try XCTUnwrap(countRows("ZMEMORIAL", at: storeURL)), 0, "the main store kept the row")
        let memorialURL = try XCTUnwrap(stack.separatedStoreURLs["Memorial"])
        XCTAssertEqual(try XCTUnwrap(countRows("ZMEMORIAL", at: memorialURL)), 1)

        // (c) not even the raw bytes of the main store carry the moved text
        try assertNoBytes(of: name, inStoreAt: storeURL)
        try assertNoBytes(of: note, inStoreAt: storeURL)
    }

    /// The compact step on its own: a file whose free pages still carry a deleted row must come out
    /// without it, in the database and in its write-ahead log.
    func test_compact_releasesTheFreePagesHoldingADeletedRow() throws {
        let storeURL = directory.appendingPathComponent("InnerLamp.sqlite")
        let name = "ZZFreePageName7f3a9c"
        try makeSQLiteFileWithDeletedRow(at: storeURL, table: "ZMEMORIAL", name: name)
        XCTAssertTrue(storeFilesHold(name, at: storeURL), "the fixture did not leave the text behind")

        XCTAssertTrue(CoreDataStackLegacySplit.compact(storeURL))

        XCTAssertFalse(storeFilesHold(name, at: storeURL), "the free pages still carry the deleted name")
        XCTAssertEqual(try XCTUnwrap(countRows("ZMEMORIAL", at: storeURL)), 0)
    }

    /// Writes a row and deletes it with plain SQLite, so the text is left in a free page exactly as
    /// a Core Data delete would leave it.
    private func makeSQLiteFileWithDeletedRow(at storeURL: URL, table: String, name: String) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        XCTAssertEqual(sqlite3_open_v2(storeURL.path, &handle, flags, nil), SQLITE_OK)
        guard let handle else { return }
        defer { sqlite3_close(handle) }

        // EN: Apple's SQLite zeroes a freed cell by default (`secure_delete = 2`), so the fixture
        // turns that off: the test needs a free page that still holds the text for VACUUM to release.
        // VI: SQLite của Apple mặc định xoá trắng ô vừa giải phóng (`secure_delete = 2`), nên fixture
        // tắt nó đi: test cần một trang trống còn giữ chữ để VACUUM trả lại.
        let sql = """
        PRAGMA secure_delete = OFF;
        PRAGMA journal_mode = WAL;
        CREATE TABLE \(table) (Z_PK INTEGER PRIMARY KEY, ZNAME TEXT);
        INSERT INTO \(table) (ZNAME) VALUES ('\(name)');
        DELETE FROM \(table);
        """
        var error: UnsafeMutablePointer<CChar>?
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, &error), SQLITE_OK)
        if let error { sqlite3_free(error) }
    }

    private func storeFilesHold(_ text: String, at storeURL: URL) -> Bool {
        for suffix in ["", "-wal"] {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: storeURL.path + suffix)) else { continue }
            if data.range(of: Data(text.utf8)) != nil { return true }
        }
        return false
    }

    /// Reads the count straight from the SQLite file: the entity is not in the store's configuration
    /// any more, so Core Data cannot fetch it back from the main store.
    private func countRows(_ table: String, at storeURL: URL) -> Int? {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &handle, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              let handle else {
            sqlite3_close(handle)
            return nil
        }
        defer { sqlite3_close(handle) }

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, "SELECT COUNT(*) FROM \(table)", -1, &statement, nil) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int64(statement, 0))
    }

    private func assertNoBytes(of text: String, inStoreAt storeURL: URL, line: UInt = #line) throws {
        for suffix in ["", "-wal", "-shm", "-journal"] {
            let fileURL = URL(fileURLWithPath: storeURL.path + suffix)
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            XCTAssertNil(
                data.range(of: Data(text.utf8)),
                "\(fileURL.lastPathComponent) still holds \(text)",
                line: line
            )
        }
    }

    // MARK: - Model 5 fixture

    private func writeModel5Store(
        at url: URL,
        name: String = "Cụ Ông",
        note: String = ""
    ) throws {
        let momd = try XCTUnwrap(
            Bundle.main.url(forResource: CoreDataStack.modelName, withExtension: "momd"),
            "The compiled model bundle is missing from the host app"
        )
        let modelURL = momd.appendingPathComponent("InnerLamp 5.mom")
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelURL))

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(type: .sqlite, at: url)

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let row = NSEntityDescription.insertNewObject(forEntityName: "Memorial", into: context)
        row.setValue("legacy-1", forKey: "id")
        row.setValue(name, forKey: "name")
        row.setValue("paternalGrandfather", forKey: "relationship")
        row.setValue("lunar", forKey: "calendarKind")
        row.setValue(15, forKey: "day")
        row.setValue(7, forKey: "month")
        row.setValue(0, forKey: "deathYear")
        row.setValue(note, forKey: "note")
        row.setValue(1, forKey: "reminderLeadDays")
        row.setValue(7, forKey: "reminderHour")
        row.setValue(0, forKey: "reminderMinute")
        row.setValue(true, forKey: "syncToReminders")

        try context.save()
        try coordinator.remove(coordinator.persistentStores.first!)
    }

    private func waitForRows(_ stack: CoreDataStack) throws -> [[String: Any]] {
        let expectation = expectation(description: "fetch")
        var result: [[String: Any]] = []
        var failure: Error?
        Task {
            do {
                result = try await stack.performBackgroundTask { context in
                    let request = NSFetchRequest<NSDictionary>(entityName: ILMemorialMO.entityName)
                    request.resultType = .dictionaryResultType
                    return try context.fetch(request).compactMap { $0 as? [String: Any] }
                }
            } catch {
                failure = error
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        if let failure { throw failure }
        return result
    }
}
