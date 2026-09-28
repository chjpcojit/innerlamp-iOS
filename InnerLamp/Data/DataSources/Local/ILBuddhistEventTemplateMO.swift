//
//  ILBuddhistEventTemplateMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for a recurring Buddhist event template.
///
/// `@objc(ILBuddhistEventTemplateMO)` must match `representedClassName` in
/// `InnerLamp.xcdatamodeld/InnerLamp.xcdatamodel/contents`. Core Data resolves the class by that
/// name at runtime, so a mismatch fails when the store is opened — not at compile time.
///
/// `tradition` is stored as the raw string of `ILBuddhistTradition` (`MAHAYANA` / `THERAVADA` /
/// `UNIVERSAL`); Core Data has no enum type. Mapping between this type and
/// `ILBuddhistEventTemplateEntity` lives in `ILBuddhistEventLocalDataSourceImpl`, and this type
/// never leaves `Data/DataSources/Local/`.
///
/// `nonisolated` for the same reason as `ILUserMO`: read and written on the background context
/// `CoreDataStack.performBackgroundTask` hands out.
@objc(ILBuddhistEventTemplateMO)
nonisolated final class ILBuddhistEventTemplateMO: NSManagedObject {

    /// Must match the entity name in the model. Kept as a constant because
    /// `NSFetchRequest<ILBuddhistEventTemplateMO>(entityName:)` is a string lookup with no
    /// compile-time check — the model uses manual codegen, so no `fetchRequest()` is generated.
    static let entityName = "BuddhistEventTemplate"

    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var eventDescription: String
    @NSManaged var lunarDay: Int16
    @NSManaged var lunarMonth: Int16
    @NSManaged var tradition: String
    @NSManaged var isLeapMonthEligible: Bool
}
