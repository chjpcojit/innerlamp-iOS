//
//  ILDeityLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Reads the "Buddhas & Bodhisattvas" catalog from Core Data, seeding the store from the bundled
/// `phat_botat.json` on first use.
///
/// Sits between `ILDeityRepositoryImpl` and `CoreDataStack`, and owns everything that is actually
/// Core Data — fetch requests, predicates, the `ILDeityMO` mapping and the seeding — so the managed
/// object types never appear outside this folder.
///
/// Seeding is idempotent: every read first checks whether any `Deity` row exists and inserts the
/// catalog only when none does. Updating the JSON therefore does **not** refresh an already-seeded
/// store; bump the model / clear the store when the catalog content changes.
///
/// `nonisolated` for the same reason as `CoreDataStack`: these methods run on the background
/// context's queue.
nonisolated protocol ILDeityLocalDataSource {

    /// Every deity, in catalog order.
    func fetchAll() async throws -> [ILDeityEntity]

    /// The deity with `id`, or `nil` when the catalog has none.
    func fetchDeity(id: String) async throws -> ILDeityEntity?

    /// Every deity of `kind`, in catalog order.
    func fetchDeities(kind: ILDeityKind) async throws -> [ILDeityEntity]

    /// Every deity that has a memorial day on the given lunar date, in catalog order.
    func fetchDeities(lunarDay: Int, lunarMonth: Int) async throws -> [ILDeityEntity]

    /// Deities whose Vietnamese, Sanskrit, Chinese name or honorific title contains `query`
    /// (case- and diacritic-insensitive), in catalog order.
    func searchDeities(query: String) async throws -> [ILDeityEntity]
}

/// Failures specific to seeding the catalog.
nonisolated enum ILDeityLocalDataSourceError: Error {
    /// `phat_botat.json` is not in the bundle (target membership / file name).
    case seedFileNotFound
}

nonisolated final class ILDeityLocalDataSourceImpl: ILDeityLocalDataSource {

    /// Name of the bundled catalog file (`Resources/Data/phat_botat.json`).
    static let seedFileName = "phat_botat"

    private let stack: CoreDataStack
    /// Source of the seed catalog. Injected so tests can seed a fixture instead of the bundle file.
    private let loadSeed: () throws -> [ILDeityEntity]

    init(stack: CoreDataStack, loadSeed: @escaping () throws -> [ILDeityEntity]) {
        self.stack = stack
        self.loadSeed = loadSeed
    }

    /// Seeds from `phat_botat.json` in `bundle`.
    convenience init(stack: CoreDataStack, bundle: Bundle = .main) {
        self.init(stack: stack) {
            try ILDeityMapper.decodeCatalog(from: Self.loadSeedData(from: bundle))
        }
    }

    func fetchAll() async throws -> [ILDeityEntity] {
        try await fetch(predicate: nil)
    }

    func fetchDeity(id: String) async throws -> ILDeityEntity? {
        try await fetch(predicate: NSPredicate(format: "id == %@", id), limit: 1).first
    }

    func fetchDeities(kind: ILDeityKind) async throws -> [ILDeityEntity] {
        try await fetch(predicate: NSPredicate(format: "kind == %@", Self.storedKind(kind)))
    }

    func fetchDeities(lunarDay: Int, lunarMonth: Int) async throws -> [ILDeityEntity] {
        // SUBQUERY so both conditions must hold on the *same* memorial day row — two `ANY` clauses
        // would match a deity with day 15 in one month and month 4 on another day.
        let predicate = NSPredicate(
            format: "SUBQUERY(memorialDays, $day, $day.lunarDay == %d AND $day.lunarMonth == %d).@count > 0",
            lunarDay, lunarMonth
        )
        return try await fetch(predicate: predicate)
    }

    func searchDeities(query: String) async throws -> [ILDeityEntity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await fetchAll() }

        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            "nameVi", "nameSanskrit", "nameChinese", "titleHonorific"
        ].map { NSPredicate(format: "%K CONTAINS[cd] %@", $0, trimmed) })
        return try await fetch(predicate: predicate)
    }

    // MARK: - Query

    private func fetch(predicate: NSPredicate?, limit: Int = 0) async throws -> [ILDeityEntity] {
        let loadSeed = loadSeed
        return try await stack.performBackgroundTask { context in
            try Self.seedIfNeeded(in: context, loadSeed: loadSeed)

            let request = NSFetchRequest<ILDeityMO>(entityName: ILDeityMO.entityName)
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            request.fetchLimit = limit
            request.relationshipKeyPathsForPrefetching = ["memorialDays"]
            return try context.fetch(request).map(Self.makeEntity(from:))
        }
    }

    // MARK: - Seeding

    /// Inserts the catalog when no rows exist yet. `performBackgroundTask` saves the context after
    /// the block returns, so the insertions are persisted without an explicit `save`.
    private static func seedIfNeeded(
        in context: NSManagedObjectContext,
        loadSeed: () throws -> [ILDeityEntity]
    ) throws {
        let countRequest = NSFetchRequest<ILDeityMO>(entityName: ILDeityMO.entityName)
        guard try context.count(for: countRequest) == 0 else { return }

        // `id` is unique in the model. If two first reads race and both seed, the later save merges
        // onto the existing rows instead of failing with a constraint conflict.
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        for (index, deity) in try loadSeed().enumerated() {
            let managed = ILDeityMO(context: context)
            try apply(deity, sortOrder: index, to: managed, in: context)
        }
    }

    private static func loadSeedData(from bundle: Bundle) throws -> Data {
        // Synchronized groups copy resources flat into the bundle root; the subdirectory lookup is
        // a fallback in case the folder is ever added as a folder reference.
        guard let url = bundle.url(forResource: seedFileName, withExtension: "json")
                ?? bundle.url(forResource: seedFileName, withExtension: "json", subdirectory: "Resources/Data")
        else {
            throw ILDeityLocalDataSourceError.seedFileNotFound
        }
        return try Data(contentsOf: url)
    }

    // MARK: - Mapping

    private static func storedKind(_ kind: ILDeityKind) -> String {
        switch kind {
        case .buddha: return "BUDDHA"
        case .bodhisattva: return "BODHISATTVA"
        }
    }

    private static func apply(
        _ entity: ILDeityEntity,
        sortOrder: Int,
        to managed: ILDeityMO,
        in context: NSManagedObjectContext
    ) throws {
        let encoder = JSONEncoder()

        managed.id = entity.id
        managed.sortOrder = Int16(sortOrder)
        managed.kind = storedKind(entity.kind)
        managed.nameVi = entity.nameVi
        managed.nameSanskrit = entity.nameSanskrit
        managed.nameChinese = entity.nameChinese
        managed.titleHonorific = entity.titleHonorific
        managed.canonicalSource = entity.canonicalSource
        managed.coreVirtue = entity.coreVirtue
        managed.pureLand = entity.pureLand
        managed.biographySummary = entity.biographySummary
        managed.greatVowsData = try encoder.encode(entity.greatVows)

        managed.posture = entity.iconography.posture
        managed.mountOrThrone = entity.iconography.mountOrThrone
        managed.sacredArtifactsData = try encoder.encode(entity.iconography.sacredArtifacts)
        managed.symbolicMeaning = entity.iconography.symbolicMeaning

        managed.mantraShortSanskrit = entity.mantra.shortSanskrit
        managed.mantraShortSinoVietnamese = entity.mantra.shortSinoVietnamese
        managed.dharaniName = entity.mantra.dharaniName
        managed.dharaniSnippet = entity.mantra.dharaniSnippet

        managed.memorialDays = NSOrderedSet(array: entity.memorialDays.map { day in
            let managedDay = ILDeityMemorialDayMO(context: context)
            managedDay.lunarDay = Int16(day.lunarDay)
            managedDay.lunarMonth = Int16(day.lunarMonth)
            managedDay.eventName = day.eventName
            return managedDay
        })
    }

    private static func makeEntity(from managed: ILDeityMO) throws -> ILDeityEntity {
        let decoder = JSONDecoder()
        let memorialDays = managed.memorialDays.array
            .compactMap { $0 as? ILDeityMemorialDayMO }
            .map {
                ILDeityMemorialDayEntity(
                    lunarDay: Int($0.lunarDay),
                    lunarMonth: Int($0.lunarMonth),
                    eventName: $0.eventName
                )
            }

        return ILDeityEntity(
            id: managed.id,
            kind: managed.kind == storedKind(.buddha) ? .buddha : .bodhisattva,
            nameVi: managed.nameVi,
            nameSanskrit: managed.nameSanskrit,
            nameChinese: managed.nameChinese,
            titleHonorific: managed.titleHonorific,
            canonicalSource: managed.canonicalSource,
            coreVirtue: managed.coreVirtue,
            pureLand: managed.pureLand,
            memorialDays: memorialDays,
            iconography: ILDeityIconographyEntity(
                posture: managed.posture,
                mountOrThrone: managed.mountOrThrone,
                sacredArtifacts: try decoder.decode([String].self, from: managed.sacredArtifactsData),
                symbolicMeaning: managed.symbolicMeaning
            ),
            biographySummary: managed.biographySummary,
            greatVows: try decoder.decode([String].self, from: managed.greatVowsData),
            mantra: ILDeityMantraEntity(
                shortSanskrit: managed.mantraShortSanskrit,
                shortSinoVietnamese: managed.mantraShortSinoVietnamese,
                dharaniName: managed.dharaniName,
                dharaniSnippet: managed.dharaniSnippet
            )
        )
    }
}
