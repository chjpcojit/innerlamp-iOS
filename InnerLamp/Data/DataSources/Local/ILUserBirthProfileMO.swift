//
//  ILUserBirthProfileMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for a user birth profile.
///
/// `@objc(ILUserBirthProfileMO)` must match `representedClassName` in
/// `InnerLamp.xcdatamodeld/InnerLamp.xcdatamodel/contents`. `element` is stored as the raw string of
/// `ILFiveElements` (`"kim"`, `"thuy"`, …); Core Data has no enum type. Mapping between this type and
/// `ILUserBirthProfileEntity` lives in `ILUserBirthProfileLocalDataSourceImpl`, and this type never
/// leaves `Data/DataSources/Local/`.
///
/// `nonisolated` for the same reason as `ILUserMO`: read and written on the background context
/// `CoreDataStack.performBackgroundTask` hands out.
@objc(ILUserBirthProfileMO)
nonisolated final class ILUserBirthProfileMO: NSManagedObject {

    /// Must match the entity name in the model. Kept as a constant because the model uses manual
    /// codegen, so no `fetchRequest()` is generated.
    static let entityName = "UserBirthProfile"

    @NSManaged var solarBirthDate: Date
    @NSManaged var lunarYear: Int32
    @NSManaged var canIndex: Int16
    @NSManaged var chiIndex: Int16
    @NSManaged var element: String
}
