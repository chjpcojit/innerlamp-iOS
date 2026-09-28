//
//  ILSutraQuoteLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Reads sutra quotes from Core Data, seeding the store from the bundled JSON catalog.
///
/// Owns everything that is Core Data or file I/O for this feature — the JSON decode, the fetch
/// requests and the `ILSutraQuoteMO` mapping — so neither leaks into `Data/Repositories/`.
///
/// Seeding inserts only the catalog records whose `stt` is not stored yet: the first launch imports
/// all of them, later launches insert nothing, and an app update that ships more quotes in the JSON
/// adds just the new ones without touching existing rows.
nonisolated protocol ILSutraQuoteLocalDataSource {

    /// Imports missing catalog records. Idempotent.
    func seedIfNeeded() async throws

    func count() async throws -> Int

    /// The row at `index` (0-based) in `sequence` order, or `nil` when out of range.
    func fetchQuote(at index: Int) async throws -> ILSutraQuoteEntity?

    func fetchAll() async throws -> [ILSutraQuoteEntity]
}

/// The bundled catalog could not be found.
nonisolated enum ILSutraQuoteSeedError: Error {
    case resourceNotFound(String)
}

nonisolated final class ILSutraQuoteLocalDataSourceImpl: ILSutraQuoteLocalDataSource {

    static let defaultResourceName = "sutra_quotes_300"

    private let stack: CoreDataStack
    private let loadSeed: () throws -> [ILSutraQuoteDTO]

    /// - Parameter loadSeed: Supplies the catalog to import. Defaults to decoding the bundled JSON;
    ///   tests inject a small in-memory catalog.
    init(stack: CoreDataStack, loadSeed: (() throws -> [ILSutraQuoteDTO])? = nil) {
        self.stack = stack
        self.loadSeed = loadSeed ?? { try Self.loadBundledCatalog() }
    }

    func seedIfNeeded() async throws {
        let seed = try loadSeed()
        try await stack.performBackgroundTask { context in
            try Self.insertMissing(seed, in: context)
        }
    }

    func count() async throws -> Int {
        try await ensureSeeded()
        return try await stack.performBackgroundTask { context in
            try context.count(for: Self.makeRequest())
        }
    }

    func fetchQuote(at index: Int) async throws -> ILSutraQuoteEntity? {
        guard index >= 0 else { return nil }
        try await ensureSeeded()
        return try await stack.performBackgroundTask { context in
            let request = Self.makeRequest()
            request.fetchOffset = index
            request.fetchLimit = 1
            return try context.fetch(request).first.map(Self.makeEntity(from:))
        }
    }

    func fetchAll() async throws -> [ILSutraQuoteEntity] {
        try await ensureSeeded()
        return try await stack.performBackgroundTask { context in
            try context.fetch(Self.makeRequest()).map(Self.makeEntity(from:))
        }
    }

    // MARK: - Seeding

    /// Reads fall back to seeding when the store is empty, so a read issued before the launch-time
    /// `seedIfNeeded()` finishes (or after it failed) still returns data.
    private func ensureSeeded() async throws {
        let isEmpty = try await stack.performBackgroundTask { context in
            try context.count(for: Self.makeRequest()) == 0
        }
        if isEmpty {
            try await seedIfNeeded()
        }
    }

    private static func insertMissing(_ seed: [ILSutraQuoteDTO], in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSDictionary>(entityName: ILSutraQuoteMO.entityName)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["sequence"]
        let stored = Set(try context.fetch(request).compactMap { ($0["sequence"] as? NSNumber)?.intValue })

        var inserted = Set<Int>()
        for dto in seed where !stored.contains(dto.stt) && !inserted.contains(dto.stt) {
            apply(dto, to: ILSutraQuoteMO(context: context))
            inserted.insert(dto.stt)
        }
        // `performBackgroundTask` saves the context after this returns.
    }

    private static func loadBundledCatalog(bundle: Bundle = .main) throws -> [ILSutraQuoteDTO] {
        // Synchronized groups flatten resources into the bundle root; keep the subdirectory lookup
        // in case the folder is ever turned into a folder reference.
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: "json")
            ?? bundle.url(forResource: defaultResourceName, withExtension: "json", subdirectory: "Data") else {
            throw ILSutraQuoteSeedError.resourceNotFound(defaultResourceName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ILSutraQuoteDTO].self, from: data)
    }

    // MARK: - Query

    private static func makeRequest() -> NSFetchRequest<ILSutraQuoteMO> {
        let request = NSFetchRequest<ILSutraQuoteMO>(entityName: ILSutraQuoteMO.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: true)]
        return request
    }

    // MARK: - Mapping

    private static func apply(_ dto: ILSutraQuoteDTO, to managed: ILSutraQuoteMO) {
        managed.sequence = Int32(dto.stt)
        managed.sutraName = dto.kinh
        managed.translator = dto.dichGia
        managed.chapterNumber = dto.phamSo
        managed.chapterName = dto.phamTen
        managed.verseNumber = Int32(dto.keSo)
        managed.content = dto.noiDung
    }

    private static func makeEntity(from managed: ILSutraQuoteMO) -> ILSutraQuoteEntity {
        ILSutraQuoteEntity(
            id: Int(managed.sequence),
            sutraName: managed.sutraName,
            translator: managed.translator,
            chapterNumber: managed.chapterNumber,
            chapterName: managed.chapterName,
            verseNumber: Int(managed.verseNumber),
            content: managed.content
        )
    }
}
