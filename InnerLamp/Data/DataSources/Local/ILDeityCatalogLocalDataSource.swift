//
//  ILDeityCatalogLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Core Data cache of the server Buddha / Bodhisattva catalog. Same shape and rules as
/// `ILTempleLocalDataSource`; `ILCachedDeityMO` never leaves this folder.
///
/// Independent of `ILDeityLocalDataSource` (the bundled `phat_botat.json` catalog): different
/// entity, no shared rows.
nonisolated protocol ILDeityCatalogLocalDataSource {

    /// Page `page` of the "show all" deities list, or `nil` when it is not fully cached.
    func cachedDeitiesPage(_ page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity>?

    func saveDeitiesPage(_ dto: ILCatalogPageDTO<ILDeitySummaryDTO>) async throws

    /// The cached top list, in order. Empty when never fetched.
    func cachedTopDeities() async throws -> [ILDeitySummaryEntity]

    func saveTopDeities(_ dtos: [ILDeitySummaryDTO]) async throws

    /// The cached full profile, or `nil` when the detail of `id` was never fetched.
    func cachedDeityDetail(id: String) async throws -> ILDeityEntity?

    func saveDeityDetail(_ dto: ILDeityDTO) async throws
}

nonisolated final class ILDeityCatalogLocalDataSourceImpl: ILDeityCatalogLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func cachedDeitiesPage(_ page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity>? {
        try await stack.performBackgroundTask { context in
            guard let rows = try ILCatalogCache.cachedPage(
                page, of: ILCachedDeityMO.self, key: .deities, in: context
            ) else { return nil }

            // Always `true` — see `ILTempleLocalDataSourceImpl.cachedTemplesPage`.
            return ILCatalogPageEntity(
                items: try rows.map { ILDeityMapper.toDomain(try Self.summaryDTO(of: $0)) },
                page: page,
                hasMore: true
            )
        }
    }

    func saveDeitiesPage(_ dto: ILCatalogPageDTO<ILDeitySummaryDTO>) async throws {
        try await stack.performBackgroundTask { context in
            let rows = try ILCatalogCache.storePage(
                dto.page, pageSize: dto.pageSize, total: dto.total,
                ids: dto.items.map(\.id), of: ILCachedDeityMO.self, key: .deities, in: context
            )
            zip(rows, dto.items).forEach { Self.apply($1, to: $0) }
        }
    }

    func cachedTopDeities() async throws -> [ILDeitySummaryEntity] {
        try await stack.performBackgroundTask { context in
            try ILCatalogCache.topRows(ILCachedDeityMO.self, in: context)
                .map { ILDeityMapper.toDomain(try Self.summaryDTO(of: $0)) }
        }
    }

    func saveTopDeities(_ dtos: [ILDeitySummaryDTO]) async throws {
        try await stack.performBackgroundTask { context in
            let rows = try ILCatalogCache.storeTop(ids: dtos.map(\.id), of: ILCachedDeityMO.self, in: context)
            zip(rows, dtos).forEach { Self.apply($1, to: $0) }
        }
    }

    func cachedDeityDetail(id: String) async throws -> ILDeityEntity? {
        try await stack.performBackgroundTask { context in
            guard let payload = try ILCatalogCache.row(ILCachedDeityMO.self, id: id, in: context)?.detailPayload
            else { return nil }
            return ILDeityMapper.toDomain(try JSONDecoder().decode(ILDeityDTO.self, from: payload))
        }
    }

    func saveDeityDetail(_ dto: ILDeityDTO) async throws {
        let payload = try JSONEncoder().encode(dto)
        try await stack.performBackgroundTask { context in
            let row = try ILCatalogCache.upsertRow(ILCachedDeityMO.self, id: dto.id, in: context)
            Self.apply(ILDeityMapper.summary(of: dto), to: row)
            row.detailPayload = payload
        }
    }

    // MARK: - Mapping

    private static func apply(_ dto: ILDeitySummaryDTO, to row: ILCachedDeityMO) {
        row.kind = dto.type.rawValue
        row.nameVi = dto.nameVi
        row.nameSanskrit = dto.nameSanskrit
        row.nameChinese = dto.nameChinese
        row.titleHonorific = dto.titleHonorific
        row.thumbnailURL = dto.thumbnailUrl
        row.imageURL = dto.imageUrl
        row.coreVirtue = dto.coreVirtue
        row.pureLand = dto.pureLand
    }

    private static func summaryDTO(of row: ILCachedDeityMO) throws -> ILDeitySummaryDTO {
        guard let type = ILDeityTypeDTO(rawValue: row.kind) else {
            throw ILCatalogCacheError.corruptRow(entity: ILCachedDeityMO.entityName, id: row.id)
        }
        return ILDeitySummaryDTO(
            id: row.id,
            type: type,
            nameVi: row.nameVi,
            nameSanskrit: row.nameSanskrit,
            nameChinese: row.nameChinese,
            titleHonorific: row.titleHonorific,
            thumbnailUrl: row.thumbnailURL,
            imageUrl: row.imageURL,
            coreVirtue: row.coreVirtue,
            pureLand: row.pureLand
        )
    }
}
