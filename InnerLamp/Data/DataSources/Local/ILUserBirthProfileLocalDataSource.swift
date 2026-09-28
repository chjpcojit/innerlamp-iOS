//
//  ILUserBirthProfileLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Reads and writes the stored user birth profile in Core Data.
///
/// Sits between `ILUserBirthProfileRepositoryImpl` and `CoreDataStack`. This type owns everything
/// that is actually Core Data — the fetch request, the `ILUserBirthProfileMO` mapping, and the
/// transaction — so `ILUserBirthProfileMO` never appears outside this file and
/// `Data/Repositories/` needs no `CoreData` import. The repository's remaining job is translating
/// storage failures into `ILUserBirthProfileError`.
///
/// `nonisolated` for the same reason as `CoreDataStack`: these methods run on the background
/// context's queue.
nonisolated protocol ILUserBirthProfileLocalDataSource {

    /// The stored birth profile, or `nil` when the store is empty.
    func fetchBirthProfile() async throws -> ILUserBirthProfileEntity?

    /// Writes `entity` as *the* birth profile row, updating the existing one when there is one.
    func saveBirthProfile(_ entity: ILUserBirthProfileEntity) async throws

    /// Removes the stored birth profile. No-op when there is none.
    func deleteBirthProfile() async throws
}

nonisolated final class ILUserBirthProfileLocalDataSourceImpl: ILUserBirthProfileLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchBirthProfile() async throws -> ILUserBirthProfileEntity? {
        try await stack.performBackgroundTask { context in
            try Self.fetchManaged(in: context).map(Self.makeEntity(from:))
        }
    }

    func saveBirthProfile(_ entity: ILUserBirthProfileEntity) async throws {
        try await stack.performBackgroundTask { context in
            // Upsert: reuse the existing row when there is one so a second save updates it instead
            // of inserting a duplicate. The stack saves whatever is left behind.
            let managed = try Self.fetchManaged(in: context) ?? ILUserBirthProfileMO(context: context)
            Self.apply(entity, to: managed)
        }
    }

    func deleteBirthProfile() async throws {
        try await stack.performBackgroundTask { context in
            try Self.fetchManaged(in: context).map(context.delete)
        }
    }

    // MARK: - Query

    private static func fetchManaged(in context: NSManagedObjectContext) throws -> ILUserBirthProfileMO? {
        let request = NSFetchRequest<ILUserBirthProfileMO>(entityName: ILUserBirthProfileMO.entityName)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Mapping

    private static func apply(_ entity: ILUserBirthProfileEntity, to managed: ILUserBirthProfileMO) {
        managed.solarBirthDate = entity.solarBirthDate
        managed.lunarYear = Int32(entity.lunarYear)
        managed.canIndex = Int16(entity.canIndex)
        managed.chiIndex = Int16(entity.chiIndex)
        managed.element = entity.element.rawValue
    }

    private static func makeEntity(from managed: ILUserBirthProfileMO) -> ILUserBirthProfileEntity {
        ILUserBirthProfileEntity(
            solarBirthDate: managed.solarBirthDate,
            lunarYear: Int(managed.lunarYear),
            canIndex: Int(managed.canIndex),
            chiIndex: Int(managed.chiIndex),
            element: ILFiveElements(rawValue: managed.element) ?? .kim
        )
    }
}
