//
//  ILUserLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Reads and writes the stored user row in Core Data.
///
/// Sits between `ILUserRepositoryImpl` and `CoreDataStack`. This type owns everything that is
/// actually Core Data — the fetch request, the `ILUserMO` mapping, and the transaction — so that
/// `ILUserMO` never appears outside this file and `Data/Repositories/` needs no `CoreData` import
/// at all. The repository's remaining job is translating storage failures into `ILUserError`.
///
/// Entity in, entity out, for the same reason the repository's protocol is: the storage shape is
/// this layer's business, and `ILUserMO` is a queue-bound `NSManagedObject` that must not escape
/// the context that produced it. `performBackgroundTask` gives each call its own private-queue
/// context and closes over it here, so nothing queue-bound is ever handed back.
///
/// `nonisolated` for the same reason as `CoreDataStack`: these methods run on the background
/// context's queue, and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would otherwise pin them to
/// the main actor.
nonisolated protocol ILUserLocalDataSource {

    /// The stored user, or `nil` when the store is empty.
    func fetchUser() async throws -> ILUserEntity?

    /// Writes `entity` as *the* user row, updating the existing one when there is one.
    ///
    /// Upsert semantics: saving twice leaves one record, not two.
    func saveUser(_ entity: ILUserEntity) async throws

    /// Removes the stored user. No-op when there is none.
    func deleteUser() async throws
}

nonisolated final class ILUserLocalDataSourceImpl: ILUserLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func fetchUser() async throws -> ILUserEntity? {
        try await stack.performBackgroundTask { context in
            try Self.fetchManaged(in: context).map(Self.makeEntity(from:))
        }
    }

    func saveUser(_ entity: ILUserEntity) async throws {
        try await stack.performBackgroundTask { context in
            // Upsert: reuse the existing row when there is one so a second save updates it
            // instead of inserting a duplicate. The stack saves whatever is left behind.
            let managed = try Self.fetchManaged(in: context) ?? ILUserMO(context: context)
            Self.apply(entity, to: managed)
        }
    }

    func deleteUser() async throws {
        try await stack.performBackgroundTask { context in
            try Self.fetchManaged(in: context).map(context.delete)
        }
    }

    // MARK: - Query

    private static func fetchManaged(in context: NSManagedObjectContext) throws -> ILUserMO? {
        let request = NSFetchRequest<ILUserMO>(entityName: ILUserMO.entityName)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Mapping

    private static func apply(_ entity: ILUserEntity, to managed: ILUserMO) {
        managed.id = entity.id
        managed.email = entity.email
        managed.phoneNumber = entity.phoneNumber
        managed.dharmaName = entity.dharmaName
        managed.ordinationPlace = entity.ordinationPlace
    }

    private static func makeEntity(from managed: ILUserMO) -> ILUserEntity {
        ILUserEntity(
            id: managed.id,
            email: managed.email,
            phoneNumber: managed.phoneNumber,
            dharmaName: managed.dharmaName,
            ordinationPlace: managed.ordinationPlace
        )
    }
}
