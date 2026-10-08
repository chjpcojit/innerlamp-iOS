//
//  ILMemorialLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Core Data access for the memorial book. Sits between `ILMemorialRepositoryImpl` and
/// `CoreDataStack`; `ILMemorialMO` never leaves this file.
nonisolated protocol ILMemorialLocalDataSource {
    func fetchAll() async throws -> [ILMemorialEntity]
    func upsert(_ entry: ILMemorialEntity) async throws
    func delete(id: String) async throws
    /// Makes the store hold exactly `entries` (the server's list is authoritative).
    func replaceAll(_ entries: [ILMemorialEntity]) async throws
}

nonisolated final class ILMemorialLocalDataSourceImpl: ILMemorialLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchAll() async throws -> [ILMemorialEntity] {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
            return try context.fetch(request).map(Self.entity(from:))
        }
    }

    func upsert(_ entry: ILMemorialEntity) async throws {
        try await stack.performBackgroundTask { context in
            let row = try Self.fetchRow(id: entry.id, in: context) ?? Self.insertRow(in: context)
            Self.apply(entry, to: row)
        }
    }

    func delete(id: String) async throws {
        try await stack.performBackgroundTask { context in
            if let row = try Self.fetchRow(id: id, in: context) {
                context.delete(row)
            }
        }
    }

    func replaceAll(_ entries: [ILMemorialEntity]) async throws {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
            for row in try context.fetch(request) { context.delete(row) }
            for entry in entries {
                Self.apply(entry, to: try Self.insertRow(in: context))
            }
        }
    }

    // MARK: - Helpers
    private static func fetchRow(id: String, in context: NSManagedObjectContext) throws -> ILMemorialMO? {
        let request = NSFetchRequest<ILMemorialMO>(entityName: ILMemorialMO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
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

    private static func apply(_ entry: ILMemorialEntity, to row: ILMemorialMO) {
        row.id = entry.id
        row.name = entry.name
        row.relationship = entry.relationship.rawValue
        row.calendarKind = entry.calendarKind.rawValue
        row.day = Int16(entry.day)
        row.month = Int16(entry.month)
        row.deathYear = Int32(entry.deathYear ?? 0)
        row.note = entry.note
        row.reminderLeadDays = Int16(entry.reminder?.leadDays ?? -1)
        row.reminderHour = Int16(entry.reminder?.hour ?? 7)
        row.reminderMinute = Int16(entry.reminder?.minute ?? 0)
        row.syncToReminders = entry.syncToReminders
        row.portraitFileName = entry.portraitFileName
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
            note: row.note,
            reminder: row.reminderLeadDays >= 0
                ? ILMemorialReminder(leadDays: Int(row.reminderLeadDays), hour: Int(row.reminderHour), minute: Int(row.reminderMinute))
                : nil,
            syncToReminders: row.syncToReminders,
            portraitFileName: row.portraitFileName
        )
    }
}
