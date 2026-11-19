//
//  CoreDataStackLegacySplit.swift
//  InnerLamp
//

import CoreData
import Foundation
import os
import SQLite3

/// EN: One-time move of rows out of the single-store layout that predates
/// `CoreDataStack.separatedStores`. Kept out of `CoreDataStack` so the generic stack stays small and
/// this migration can be deleted once no installed build predates the split.
/// VI: Việc chuyển một lần các dòng ra khỏi layout một-store trước khi có
/// `CoreDataStack.separatedStores`. Tách khỏi `CoreDataStack` để stack chung gọn và có thể xoá phần
/// migration này khi không còn bản cài nào trước khi tách.
///
/// EN: Deleting a row does not erase its text: SQLite leaves the pages holding it as free space, and
/// the main store is backup-eligible after the split, so a name and a note would still travel in a
/// device backup. The move is therefore only marked done after `VACUUM`, `wal_checkpoint(TRUNCATE)`
/// and a re-read that sees no row of the entity left.
/// VI: Xoá một dòng không xoá chữ của nó: SQLite để các trang chứa nó thành chỗ trống, mà store
/// chính được phép vào backup sau khi tách, nên tên và ghi chú vẫn theo bản backup thiết bị. Vì thế
/// việc chuyển chỉ được đánh dấu xong sau `VACUUM`, `wal_checkpoint(TRUNCATE)` và một lần đọc lại
/// thấy không còn dòng nào của entity.
nonisolated enum CoreDataStackLegacySplit {

    private static let logger = Logger(
        subsystem: "weedigital.vn.InnerLamp",
        category: "CoreDataStackLegacySplit"
    )

    /// EN: `UserDefaults` key of the "the old store was compacted and re-read as empty" marker. It
    /// lives outside the store on purpose: a store cannot vouch for its own free pages.
    /// VI: Khoá `UserDefaults` của dấu "store cũ đã được nén và đọc lại thấy rỗng". Dấu nằm ngoài
    /// store có chủ đích: một store không thể tự bảo lãnh cho các trang trống của chính nó.
    static func markerKey(for configurationName: String) -> String {
        "CoreDataStack.legacySplit.vacuumed.\(configurationName)"
    }

    /// EN: Drains every separated store that has a legacy entity and still has work to do. Callers
    /// skip this for an in-memory stack: it has no file whose free pages could keep a name.
    /// VI: Rút dữ liệu cho mỗi store tách riêng có entity cũ và còn việc phải làm. Nơi gọi bỏ qua
    /// việc này với stack trong bộ nhớ: nó không có file nào giữ tên trong các trang trống.
    static func drain(
        separatedStores: [CoreDataStack.SeparatedStore],
        mainURL: URL?,
        separatedURLs: [String: URL],
        model: NSManagedObjectModel,
        defaults: UserDefaults
    ) -> [String: [[String: Any]]] {
        guard let mainURL else { return [:] }
        var rows: [String: [[String: Any]]] = [:]
        for separated in separatedStores {
            let configurationName = separated.configurationName
            guard let entityName = separated.legacyEntityName,
                  let separatedURL = separatedURLs[configurationName] else { continue }
            guard needsDrain(
                separatedURL: separatedURL,
                configurationName: configurationName,
                defaults: defaults
            ) else { continue }

            rows[configurationName] = drainRows(
                entityName: entityName,
                from: mainURL,
                model: model,
                configurationName: configurationName,
                defaults: defaults
            )
        }
        return rows
    }

    /// EN: Restores the drained rows into the store the container routes their entity to.
    /// VI: Đưa các dòng đã rút vào store mà container định tuyến entity của chúng tới.
    static func restore(
        _ rows: [String: [[String: Any]]],
        separatedStores: [CoreDataStack.SeparatedStore],
        into context: NSManagedObjectContext
    ) {
        for separated in separatedStores {
            guard let entityName = separated.legacyEntityName,
                  let values = rows[separated.configurationName]
            else { continue }
            insert(values, entityName: entityName, into: context)
        }
    }

    /// EN: The separated store's file already shows the split, but a launch that moved the rows and
    /// could not compact the old file must try again even though that file now exists.
    /// VI: File của store tách riêng vốn cho thấy việc tách, nhưng một lần chạy đã chuyển dòng mà
    /// chưa nén được store cũ phải thử lại dù file đó giờ đã tồn tại.
    private static func needsDrain(
        separatedURL: URL,
        configurationName: String,
        defaults: UserDefaults
    ) -> Bool {
        !FileManager.default.fileExists(atPath: separatedURL.path)
            || !defaults.bool(forKey: markerKey(for: configurationName))
    }

    /// EN: Moves the rows out of `storeURL`, compacts it and only then records the migration as
    /// done. A step that fails leaves the marker unset, so the next launch runs this again instead
    /// of trusting a half-finished move.
    /// VI: Chuyển các dòng ra khỏi `storeURL`, nén file rồi mới ghi nhận migration xong. Bước nào
    /// lỗi thì dấu chưa được đặt, lần chạy sau làm lại thay vì tin vào một lần chuyển dở dang.
    private static func drainRows(
        entityName: String,
        from storeURL: URL,
        model: NSManagedObjectModel,
        configurationName: String,
        defaults: UserDefaults
    ) -> [[String: Any]] {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            // EN: Nothing on disk can hold a legacy row, so there is nothing to compact.
            // VI: Trên đĩa không có gì chứa dòng cũ, nên không có gì phải nén.
            defaults.set(true, forKey: markerKey(for: configurationName))
            return []
        }

        let extracted = extract(entityName: entityName, from: storeURL, model: model)
        guard extracted.moved else { return [] }
        guard compact(storeURL) else { return extracted.rows }

        guard let remaining = rowCount(entityName: entityName, at: storeURL), remaining == 0 else {
            // EN: The moved rows are gone from this store either way, so they still go to the
            // memorial store; only the marker waits for a later launch to try again.
            // VI: Các dòng đã chuyển thì đã rời store này, nên vẫn được đưa sang store sổ giỗ; chỉ
            // dấu là chờ lần chạy sau thử lại.
            logger.error("legacy split: main store was not re-read as empty; not marked done")
            return extracted.rows
        }
        defaults.set(true, forKey: markerKey(for: configurationName))
        return extracted.rows
    }

    /// EN: Copies the rows of `entityName` out of a pre-split store and deletes them there. The
    /// store is opened with the current model and no configuration, so it still sees the entity
    /// the split has since moved to another store.
    /// VI: Chép các dòng `entityName` ra khỏi store trước khi tách và xoá chúng ở đó. Store được mở
    /// bằng model hiện tại và không chỉ định cấu hình, nên vẫn thấy entity mà việc tách đã chuyển
    /// sang store khác.
    ///
    /// `moved` is `false` when the rows are still in the old store, so the caller restores nothing.
    private static func extract(
        entityName: String,
        from storeURL: URL,
        model: NSManagedObjectModel
    ) -> (rows: [[String: Any]], moved: Bool) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options: [AnyHashable: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        guard let store = try? coordinator.addPersistentStore(
            type: .sqlite,
            at: storeURL,
            options: options
        ) else {
            logger.error("legacy split: the main store could not be opened; not marked done")
            return ([], false)
        }

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        var rows: [[String: Any]] = []
        var moved = false
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            guard let objects = try? context.fetch(request) else { return }
            rows = objects.map { object in
                var values: [String: Any] = [:]
                for key in object.entity.attributesByName.keys {
                    if let value = object.value(forKey: key) {
                        values[key] = value
                    }
                }
                return values
            }
            for object in objects {
                context.delete(object)
            }
            do {
                try context.save()
                moved = true
            } catch {
                context.rollback()
                logger.error("legacy split: deleting the moved rows failed; not marked done")
            }
        }
        try? coordinator.remove(store)
        return (rows, moved)
    }

    /// EN: Rewrites the store so the free pages left by the deleted rows are released, then
    /// truncates the write-ahead log that would otherwise still carry them. Internal rather than
    /// private so a test can prove those pages are released.
    /// VI: Ghi lại store để trả các trang trống còn lại của những dòng đã xoá, rồi cắt log
    /// write-ahead mà nếu không sẽ vẫn mang chúng. Để mức internal thay vì private để test chứng
    /// minh được các trang đó đã được trả.
    static func compact(_ storeURL: URL) -> Bool {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &handle, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              let handle else {
            sqlite3_close(handle)
            logger.error("legacy split: the main store could not be opened to VACUUM it")
            return false
        }
        defer { sqlite3_close(handle) }

        guard execute("VACUUM", on: handle) else { return false }
        guard execute("PRAGMA wal_checkpoint(TRUNCATE)", on: handle) else { return false }

        // EN: A checkpoint that is refused on a busy log returns OK but leaves frames behind.
        // VI: Một lần checkpoint bị từ chối vì log đang bận vẫn trả OK nhưng để lại các frame.
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        if let size = try? walURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 {
            logger.error("legacy split: the write-ahead log still holds \(size) bytes; not marked done")
            return false
        }
        return true
    }

    /// EN: Runs one statement and logs the engine's own message when it fails.
    /// VI: Chạy một câu lệnh và ghi lại thông điệp của engine khi nó lỗi.
    private static func execute(_ sql: String, on handle: OpaquePointer) -> Bool {
        var message: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &message)
        guard result == SQLITE_OK else {
            let text = message.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(handle))
            if let message { sqlite3_free(message) }
            logger.error("legacy split: \(sql, privacy: .public) failed (\(result)): \(text, privacy: .public)")
            return false
        }
        return true
    }

    /// EN: Counts the entity's rows straight from the SQLite file, so the check does not depend on
    /// the container being able to open the store again.
    /// VI: Đếm số dòng của entity thẳng từ file SQLite, để phép kiểm không phụ thuộc vào việc
    /// container mở lại được store hay không.
    private static func rowCount(entityName: String, at storeURL: URL) -> Int? {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &handle, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              let handle else {
            sqlite3_close(handle)
            return nil
        }
        defer { sqlite3_close(handle) }

        guard let table = tableName(entityName: entityName, on: handle) else { return 0 }
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, "SELECT COUNT(*) FROM \"\(table)\"", -1, &statement, nil) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int64(statement, 0))
    }

    /// EN: The table Core Data keeps an entity in, or `nil` when the store predates the entity.
    /// VI: Bảng mà Core Data giữ một entity, hoặc `nil` khi store có trước entity đó.
    private static func tableName(entityName: String, on handle: OpaquePointer) -> String? {
        let expected = "Z" + entityName.uppercased()
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        let sql = "SELECT name FROM sqlite_master WHERE type = 'table' AND name = '\(expected)' COLLATE NOCASE"
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_ROW,
              let text = sqlite3_column_text(statement, 0) else { return nil }
        return String(cString: text)
    }

    /// EN: Inserts plain attribute dictionaries as new managed objects.
    /// VI: Thêm các từ điển thuộc tính thành managed object mới.
    private static func insert(
        _ rows: [[String: Any]],
        entityName: String,
        into context: NSManagedObjectContext
    ) {
        guard !rows.isEmpty else { return }
        context.performAndWait {
            for values in rows {
                let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                for (key, value) in values {
                    object.setValue(value, forKey: key)
                }
            }
            try? context.save()
        }
    }
}
