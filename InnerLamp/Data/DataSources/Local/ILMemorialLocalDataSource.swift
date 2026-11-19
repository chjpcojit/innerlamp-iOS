//
//  ILMemorialLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// EN: The cache cannot answer without a signed-in account. It must never fall back to "all rows".
/// VI: Cache không thể trả lời khi chưa đăng nhập. Không bao giờ fallback về "mọi dòng".
nonisolated enum ILMemorialCacheError: Error {
    case noAccount
}

/// Core Data access for the memorial book. Sits between `ILMemorialRepositoryImpl` and
/// `CoreDataStack`; `ILMemorialMO` never leaves this file.
///
/// Every operation is scoped to `ILAccountIdentityProviding.currentAccountID()`. A read with no
/// account returns an error instead of another account's rows; `replaceAll` only removes the
/// current account's rows (security review G1, item 2). Rows with an empty owner (migrated from
/// model 5) are purged on the first read/write.
nonisolated protocol ILMemorialLocalDataSource {
    func fetchAll() async throws -> [ILMemorialEntity]
    func upsert(_ entry: ILMemorialEntity) async throws
    func delete(id: String) async throws
    /// Makes the store hold exactly `entries` for the current account.
    func replaceAll(_ entries: [ILMemorialEntity]) async throws
}

nonisolated final class ILMemorialLocalDataSourceImpl: ILMemorialLocalDataSource {

    private let stack: CoreDataStack
    private let accountIdentity: ILAccountIdentityProviding

    init(stack: CoreDataStack, accountIdentity: ILAccountIdentityProviding) {
        self.stack = stack
        self.accountIdentity = accountIdentity
    }

    func fetchAll() async throws -> [ILMemorialEntity] {
        let owner = try await requireOwner()
        return try await stack.performBackgroundTask { context in
            Self.purgeUnownedRows(in: context)
            let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
            request.predicate = NSPredicate(format: "ownerAccountID == %@", owner)
            return try context.fetch(request).map(Self.entity(from:))
        }
    }

    func upsert(_ entry: ILMemorialEntity) async throws {
        let owner = try await requireOwner()
        try await stack.performBackgroundTask { context in
            let row = try Self.fetchRow(id: entry.id, owner: owner, in: context) ?? Self.insertRow(in: context)
            Self.apply(entry, owner: owner, to: row)
        }
    }

    func delete(id: String) async throws {
        let owner = try await requireOwner()
        try await stack.performBackgroundTask { context in
            if let row = try Self.fetchRow(id: id, owner: owner, in: context) {
                context.delete(row)
            }
        }
    }

    func replaceAll(_ entries: [ILMemorialEntity]) async throws {
        let owner = try await requireOwner()
        try await stack.performBackgroundTask { context in
            Self.purgeUnownedRows(in: context)
            // Only this account's rows: another account's cache is not ours to delete.
            let owned = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
            owned.predicate = NSPredicate(format: "ownerAccountID == %@", owner)
            for row in try context.fetch(owned) { context.delete(row) }
            for entry in entries {
                Self.apply(entry, owner: owner, to: try Self.insertRow(in: context))
            }
        }
    }

    // MARK: - Helpers

    private func requireOwner() async throws -> String {
        guard let owner = await accountIdentity.currentAccountID(), !owner.isEmpty else {
            throw ILMemorialCacheError.noAccount
        }
        return owner
    }

    private static func fetchRow(id: String, owner: String, in context: NSManagedObjectContext) throws -> ILMemorialMO? {
        let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
        request.predicate = NSPredicate(format: "id == %@ AND ownerAccountID == %@", id, owner)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Throws (instead of crashing) when the loaded model has no `Memorial` entity, i.e. the model
    /// version was not updated.
    private static func insertRow(in context: NSManagedObjectContext) throws -> ILMemorialMO {
        guard let row = NSEntityDescription.insertNewObject(
            forEntityName: ILMemorialMO.entityName, into: context
        ) as? ILMemorialMO else {
            throw CocoaError(.coreData)
        }
        return row
    }

    private static func purgeUnownedRows(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
        request.predicate = NSPredicate(format: "ownerAccountID == nil OR ownerAccountID == %@", "")
        for row in (try? context.fetch(request)) ?? [] {
            context.delete(row)
        }
    }

    private static func apply(_ entry: ILMemorialEntity, owner: String, to row: ILMemorialMO) {
        row.id = entry.id
        row.ownerAccountID = owner
        row.name = entry.name
        row.relationship = entry.relationship.rawValue
        row.calendarKind = entry.calendarKind.rawValue
        row.day = Int16(entry.day)
        row.month = Int16(entry.month)
        row.deathYear = Int32(entry.deathYear ?? 0)
        row.deathLeapMonth = entry.deathLeapMonth
        row.note = entry.note
        row.reminderLeadDays = Int16(entry.reminder?.leadDays ?? -1)
        row.reminderHour = Int16(entry.reminder?.hour ?? 7)
        row.reminderMinute = Int16(entry.reminder?.minute ?? 0)
        // EN: D8 — never persist the signed photo URL; the cache only says there is no photo.
        // VI: D8 — không lưu URL ảnh có chữ ký; bản cache chỉ biết là không có ảnh.
    }

    private static func entity(from row: ILMemorialMO) -> ILMemorialEntity {
        ILMemorialEntity(
            id: row.id,
            name: row.name,
            relationship: ILMemorialRelationship(rawValue: row.relationship) ?? .other,
            calendarKind: ILMemorialCalendarKind(rawValue: row.calendarKind) ?? .lunar,
            day: Int(row.day),
            month: Int(row.month),
            deathYear: row.deathYear > 0 ? Int(row.deathYear) : nil,
            deathLeapMonth: row.deathLeapMonth,
            note: row.note,
            reminder: row.reminderLeadDays >= 0
                ? ILMemorialReminder(leadDays: Int(row.reminderLeadDays), hour: Int(row.reminderHour), minute: Int(row.reminderMinute))
                : nil,
            photoURL: nil
        )
    }
}
