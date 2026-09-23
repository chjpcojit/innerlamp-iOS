//
//  ILUserMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for a user account.
///
/// `@objc(ILUserMO)` must match `representedClassName` in
/// `InnerLamp.xcdatamodeld/InnerLamp.xcdatamodel/contents`. Core Data resolves the class by that
/// name at runtime, so a mismatch fails when the store is opened — not at compile time.
///
/// The attributes mirror `ILUserEntity` field for field. Mapping between the two lives in
/// `ILUserLocalDataSourceImpl`; this type never leaves `Data/DataSources/Local/`, and nothing above
/// the Repository layer ever sees it.
///
/// `nonisolated` so it can be read and written on the background context
/// `CoreDataStack.performBackgroundTask` hands out. Core Data objects are queue-bound, not actor
/// bound, and the queue they belong to is not the main one here.
@objc(ILUserMO)
nonisolated final class ILUserMO: NSManagedObject {

    /// Must match the entity name in the model. Kept as a constant because
    /// `NSFetchRequest<ILUserMO>(entityName:)` is a string lookup with no compile-time check —
    /// `ILUserMO.fetchRequest()` is not generated, since the model uses manual codegen.
    static let entityName = "User"

    @NSManaged var id: Int64
    @NSManaged var email: String
    @NSManaged var phoneNumber: String
    @NSManaged var dharmaName: String
    @NSManaged var ordinationPlace: String
}
