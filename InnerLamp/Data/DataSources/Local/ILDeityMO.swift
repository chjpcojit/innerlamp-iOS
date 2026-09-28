//
//  ILDeityMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for one Buddha / Bodhisattva of the catalog.
///
/// `@objc(ILDeityMO)` must match `representedClassName` in
/// `InnerLamp.xcdatamodeld/InnerLamp.xcdatamodel/contents`. Core Data resolves the class by that
/// name at runtime, so a mismatch fails when the store is opened — not at compile time.
///
/// Storage choices:
/// - `kind` is the raw catalog value (`BUDDHA` / `BODHISATTVA`); Core Data has no enum type.
/// - Iconography and mantra are flattened into columns — they are 1:1 with the deity.
/// - `sacredArtifactsData` / `greatVowsData` are JSON-encoded `[String]`. They are only ever read
///   whole, never queried, so a relationship would add rows without adding value.
/// - Memorial days are a real ordered to-many relationship, because they *are* queried
///   (`fetchDeities(lunarDay:lunarMonth:)`).
/// - `sortOrder` keeps the catalog file order, which a fetch would otherwise not preserve.
///
/// Mapping to `ILDeityEntity` lives in `ILDeityLocalDataSourceImpl`; this type never leaves
/// `Data/DataSources/Local/`. `nonisolated` for the same reason as `ILUserMO`.
@objc(ILDeityMO)
nonisolated final class ILDeityMO: NSManagedObject {

    /// Must match the entity name in the model (manual codegen — no generated `fetchRequest()`).
    static let entityName = "Deity"

    @NSManaged var id: String
    @NSManaged var sortOrder: Int16
    @NSManaged var kind: String
    @NSManaged var nameVi: String
    @NSManaged var nameSanskrit: String
    @NSManaged var nameChinese: String
    @NSManaged var titleHonorific: String
    @NSManaged var canonicalSource: String
    @NSManaged var coreVirtue: String
    @NSManaged var pureLand: String
    @NSManaged var biographySummary: String
    @NSManaged var greatVowsData: Data

    // Iconography
    @NSManaged var posture: String
    @NSManaged var mountOrThrone: String
    @NSManaged var sacredArtifactsData: Data
    @NSManaged var symbolicMeaning: String

    // Mantra
    @NSManaged var mantraShortSanskrit: String
    @NSManaged var mantraShortSinoVietnamese: String
    @NSManaged var dharaniName: String
    @NSManaged var dharaniSnippet: String

    /// Ordered set of `ILDeityMemorialDayMO`, in catalog order.
    @NSManaged var memorialDays: NSOrderedSet
}

/// One lunar memorial day of a deity. Cascade-deleted with its owning `ILDeityMO`.
@objc(ILDeityMemorialDayMO)
nonisolated final class ILDeityMemorialDayMO: NSManagedObject {

    static let entityName = "DeityMemorialDay"

    @NSManaged var lunarDay: Int16
    @NSManaged var lunarMonth: Int16
    @NSManaged var eventName: String
    @NSManaged var deity: ILDeityMO?
}
