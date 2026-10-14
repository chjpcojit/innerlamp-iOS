//
//  ILLampLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Core Data access for lit lamps. Sits between `ILLampRepositoryImpl` and `CoreDataStack`;
/// `ILLampMO` never leaves this file.
nonisolated protocol ILLampLocalDataSource {
    func fetchAll() async throws -> [ILLampEntity]
    func upsert(_ lamp: ILLampEntity) async throws
}

nonisolated final class ILLampLocalDataSourceImpl: ILLampLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchAll() async throws -> [ILLampEntity] {
        try await stack.performBackgroundTask { context in
            let request = NSFetchRequest<ILLampMO>(entityName: ILLampMO.entityName)
            return try context.fetch(request).map(Self.entity(from:))
        }
    }

    func upsert(_ lamp: ILLampEntity) async throws {
        try await stack.performBackgroundTask { context in
            let row = try Self.fetchRow(id: lamp.id, in: context) ?? Self.insertRow(in: context)
            Self.apply(lamp, to: row)
        }
    }

    // MARK: - Helpers
    private static func fetchRow(id: String, in context: NSManagedObjectContext) throws -> ILLampMO? {
        let request = NSFetchRequest<ILLampMO>(entityName: ILLampMO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Throws (instead of crashing) when the loaded model has no `Lamp` entity, i.e. the model
    /// version was not updated.
    private static func insertRow(in context: NSManagedObjectContext) throws -> ILLampMO {
        guard let row = NSEntityDescription.insertNewObject(
            forEntityName: ILLampMO.entityName, into: context
        ) as? ILLampMO else {
            throw CocoaError(.coreData)
        }
        return row
    }

    private static func apply(_ lamp: ILLampEntity, to row: ILLampMO) {
        row.id = lamp.id
        row.kind = lamp.kind.rawValue
        row.intention = lamp.intention.rawValue
        row.target = lamp.target
        row.vow = lamp.vow
        row.durationDays = Int16(clamping: lamp.durationDays)
        row.litAt = lamp.litAt
    }

    private static func entity(from row: ILLampMO) -> ILLampEntity {
        ILLampEntity(
            id: row.id,
            kind: ILLampKind(rawValue: row.kind) ?? .oil,
            intention: ILLampIntention(rawValue: row.intention) ?? .peace,
            target: row.target,
            vow: row.vow,
            durationDays: Int(row.durationDays),
            litAt: row.litAt
        )
    }
}
