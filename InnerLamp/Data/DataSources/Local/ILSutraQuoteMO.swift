//
//  ILSutraQuoteMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for a sutra quote.
///
/// `@objc(ILSutraQuoteMO)` must match `representedClassName` in
/// `InnerLamp.xcdatamodeld/InnerLamp.xcdatamodel/contents`. `sequence` holds the catalog's `stt`
/// and carries a uniqueness constraint. Mapping to `ILSutraQuoteEntity` lives in
/// `ILSutraQuoteLocalDataSourceImpl`; this type never leaves `Data/DataSources/Local/`.
///
/// `nonisolated` for the same reason as `ILUserMO`: used on the background context.
@objc(ILSutraQuoteMO)
nonisolated final class ILSutraQuoteMO: NSManagedObject {

    /// Must match the entity name in the model (manual codegen — no generated `fetchRequest()`).
    static let entityName = "SutraQuote"

    @NSManaged var sequence: Int32
    @NSManaged var sutraName: String
    @NSManaged var translator: String
    @NSManaged var chapterNumber: String
    @NSManaged var chapterName: String
    @NSManaged var verseNumber: Int32
    @NSManaged var content: String
}
