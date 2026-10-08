//
//  ILCatalogCacheMO.swift
//  InnerLamp
//

import CoreData

/// A cached row of a server-backed catalog (temple, deity). Lets `ILCatalogCache` run the
/// list/top bookkeeping once for every catalog.
///
/// - `listPosition`: absolute 0-based index in the "show all" list (`-1` = not in the list cache).
///   Page `p` of size `n` covers positions `(p-1)*n ..< p*n`.
/// - `topPosition`: index in the "top" list (`-1` = not featured).
nonisolated protocol ILCatalogCachedRow: NSManagedObject {
    static var entityName: String { get }
    var id: String { get set }
    var listPosition: Int32 { get set }
    var topPosition: Int32 { get set }
}

/// Core Data storage for one temple of the server catalog.
///
/// `@objc(...)` must match `representedClassName` in `InnerLamp 2.xcdatamodel`. Summary fields are
/// columns (raw wire values — `ILTempleMapper` turns them into Domain enums on read). The
/// detail-only fields are an encoded `ILTempleDetailDTO` in `detailPayload`: they are only ever
/// read whole, never queried. `nil` payload = detail never fetched.
@objc(ILCachedTempleMO)
nonisolated final class ILCachedTempleMO: NSManagedObject, ILCatalogCachedRow {

    static let entityName = "CachedTemple"

    @NSManaged var id: String
    @NSManaged var listPosition: Int32
    @NSManaged var topPosition: Int32
    @NSManaged var name: String
    @NSManaged var type: String
    @NSManaged var region: String
    @NSManaged var thumbnailURL: String?
    @NSManaged var imageURL: String?
    @NSManaged var sect: String
    @NSManaged var heritageRank: String
    @NSManaged var establishedYear: Int32
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var address: String
    @NSManaged var detailPayload: Data?
}

/// Core Data storage for one Buddha / Bodhisattva of the server catalog. Same layout rules as
/// `ILCachedTempleMO`; `detailPayload` is an encoded `ILDeityDTO`.
///
/// Distinct from `ILDeityMO`, which holds the catalog bundled with the app.
@objc(ILCachedDeityMO)
nonisolated final class ILCachedDeityMO: NSManagedObject, ILCatalogCachedRow {

    static let entityName = "CachedDeity"

    @NSManaged var id: String
    @NSManaged var listPosition: Int32
    @NSManaged var topPosition: Int32
    /// Raw wire value, `BUDDHA` / `BODHISATTVA`.
    @NSManaged var kind: String
    @NSManaged var nameVi: String
    @NSManaged var nameSanskrit: String
    @NSManaged var nameChinese: String
    @NSManaged var titleHonorific: String
    @NSManaged var thumbnailURL: String
    @NSManaged var imageURL: String
    @NSManaged var coreVirtue: String
    @NSManaged var pureLand: String
    @NSManaged var detailPayload: Data?
}

/// Paging metadata of one cached "show all" list, keyed by `ILCatalogListKey`.
@objc(ILCatalogListStateMO)
nonisolated final class ILCatalogListStateMO: NSManagedObject {

    static let entityName = "CatalogListState"

    @NSManaged var key: String
    /// Server page size the cached positions were laid out with.
    @NSManaged var pageSize: Int32
    /// Server `total` when the list was last fetched.
    @NSManaged var total: Int32
}
