//
//  ILCatalogCache.swift
//  InnerLamp
//

import CoreData

/// Failures specific to the catalog cache's storage (as opposed to Core Data's own errors).
nonisolated enum ILCatalogCacheError: Error {
    /// The entity's `representedClassName` does not match the Swift row class.
    case entityClassMismatch(String)
    /// A stored raw value can no longer be decoded (e.g. an unknown deity kind).
    case corruptRow(entity: String, id: String)
}

/// Identifies one cached "show all" list in `CatalogListState`.
nonisolated enum ILCatalogListKey: String {
    case temples
    case deities
}

/// Paging / top-list bookkeeping shared by the catalog local data sources. Every function runs
/// inside a context the caller got from `CoreDataStack.performBackgroundTask`.
///
/// Page layout: rows carry an absolute `listPosition`, so a page is the position range
/// `(page-1)*pageSize ..< page*pageSize`. A page counts as cached only when that range holds every
/// row the recorded `total` says it should (`pageSize`, or fewer on the last page). A page with
/// holes, or a page past the recorded end, is "local ran out" → the repository asks the server.
///
/// When the server's `total` or `pageSize` changes, the whole list layout is reset — positions
/// from the old layout no longer line up with the server's pages.
nonisolated enum ILCatalogCache {

    // MARK: - Read

    /// Rows of `page` in list order, or `nil` when the page is not fully cached.
    static func cachedPage<Row: ILCatalogCachedRow>(
        _ page: Int,
        of _: Row.Type,
        key: ILCatalogListKey,
        in context: NSManagedObjectContext
    ) throws -> [Row]? {
        guard page >= 1,
              let state = try listState(key, in: context),
              state.pageSize > 0
        else { return nil }

        let pageSize = Int(state.pageSize)
        let lower = (page - 1) * pageSize
        let expected = min(pageSize, Int(state.total) - lower)
        guard expected > 0 else { return nil }

        let request = NSFetchRequest<Row>(entityName: Row.entityName)
        request.predicate = NSPredicate(
            format: "listPosition >= %d AND listPosition < %d", lower, lower + pageSize
        )
        request.sortDescriptors = [NSSortDescriptor(key: "listPosition", ascending: true)]
        let rows = try context.fetch(request)

        return rows.count == expected ? rows : nil
    }

    /// Rows of the top list, in order. Empty when never fetched.
    static func topRows<Row: ILCatalogCachedRow>(
        _: Row.Type,
        in context: NSManagedObjectContext
    ) throws -> [Row] {
        let request = NSFetchRequest<Row>(entityName: Row.entityName)
        request.predicate = NSPredicate(format: "topPosition >= 0")
        request.sortDescriptors = [NSSortDescriptor(key: "topPosition", ascending: true)]
        return try context.fetch(request)
    }

    static func row<Row: ILCatalogCachedRow>(
        _: Row.Type,
        id: String,
        in context: NSManagedObjectContext
    ) throws -> Row? {
        let request = NSFetchRequest<Row>(entityName: Row.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Write

    /// Records one server page and returns the row for each item id, positioned in list order.
    /// `apply` fills the caller's summary columns on each returned row.
    static func storePage<Row: ILCatalogCachedRow>(
        _ page: Int,
        pageSize: Int,
        total: Int,
        ids: [String],
        of _: Row.Type,
        key: ILCatalogListKey,
        in context: NSManagedObjectContext
    ) throws -> [Row] {
        prepareForWrites(context)

        let state = try listState(key, in: context) ?? {
            let created = ILCatalogListStateMO(context: context)
            created.key = key.rawValue
            return created
        }()
        if Int(state.pageSize) != pageSize || Int(state.total) != total {
            try clearPositions(of: Row.self, keyPath: "listPosition", in: context)
            state.pageSize = Int32(pageSize)
            state.total = Int32(total)
        }

        // Drop rows that used to sit on this page but are no longer on it.
        let lower = (page - 1) * pageSize
        let stale = NSFetchRequest<Row>(entityName: Row.entityName)
        stale.predicate = NSPredicate(
            format: "listPosition >= %d AND listPosition < %d AND NOT (id IN %@)",
            lower, lower + pageSize, ids
        )
        try context.fetch(stale).forEach { $0.listPosition = -1 }

        return try ids.enumerated().map { index, id in
            let row = try upsertRow(Row.self, id: id, in: context)
            row.listPosition = Int32(lower + index)
            return row
        }
    }

    /// Replaces the top list with `ids`, in order, and returns their rows.
    static func storeTop<Row: ILCatalogCachedRow>(
        ids: [String],
        of _: Row.Type,
        in context: NSManagedObjectContext
    ) throws -> [Row] {
        prepareForWrites(context)
        try clearPositions(of: Row.self, keyPath: "topPosition", in: context)

        return try ids.enumerated().map { index, id in
            let row = try upsertRow(Row.self, id: id, in: context)
            row.topPosition = Int32(index)
            return row
        }
    }

    /// The row with `id`, inserted (with no list/top position) when missing.
    static func upsertRow<Row: ILCatalogCachedRow>(
        _: Row.Type,
        id: String,
        in context: NSManagedObjectContext
    ) throws -> Row {
        prepareForWrites(context)
        if let existing = try row(Row.self, id: id, in: context) {
            return existing
        }
        let inserted = NSEntityDescription.insertNewObject(forEntityName: Row.entityName, into: context)
        guard let created = inserted as? Row else {
            // `entityName` and `representedClassName` disagree — a model/class mismatch.
            context.delete(inserted)
            throw ILCatalogCacheError.entityClassMismatch(Row.entityName)
        }
        created.id = id
        created.listPosition = -1
        created.topPosition = -1
        return created
    }

    // MARK: - Helpers

    /// `id` / `key` are unique in the model. If two writes race on different contexts, the later
    /// save merges onto the existing row instead of failing with a constraint conflict.
    private static func prepareForWrites(_ context: NSManagedObjectContext) {
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func listState(
        _ key: ILCatalogListKey,
        in context: NSManagedObjectContext
    ) throws -> ILCatalogListStateMO? {
        let request = NSFetchRequest<ILCatalogListStateMO>(entityName: ILCatalogListStateMO.entityName)
        request.predicate = NSPredicate(format: "key == %@", key.rawValue)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func clearPositions<Row: ILCatalogCachedRow>(
        of _: Row.Type,
        keyPath: String,
        in context: NSManagedObjectContext
    ) throws {
        let request = NSFetchRequest<Row>(entityName: Row.entityName)
        request.predicate = NSPredicate(format: "%K >= 0", keyPath)
        try context.fetch(request).forEach { $0.setValue(Int32(-1), forKey: keyPath) }
    }
}
