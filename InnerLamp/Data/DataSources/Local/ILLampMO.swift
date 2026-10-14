//
//  ILLampMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for 1 lit lamp.
///
/// `@objc(ILLampMO)` must match `representedClassName` of the `Lamp` entity in
/// `InnerLamp 5.xcdatamodel` (a mismatch fails when the store is opened, not at compile time).
/// `kind` / `intention` hold the raw strings of `ILLampKind` / `ILLampIntention`. The mapping to and
/// from `ILLampEntity` lives in `ILLampLocalDataSourceImpl` and this type never leaves
/// `Data/DataSources/Local/`.
@objc(ILLampMO)
nonisolated final class ILLampMO: NSManagedObject {

    static let entityName = "Lamp"

    @NSManaged var id: String
    @NSManaged var kind: String
    @NSManaged var intention: String
    @NSManaged var target: String
    @NSManaged var vow: String
    @NSManaged var durationDays: Int16
    @NSManaged var litAt: Date
}
