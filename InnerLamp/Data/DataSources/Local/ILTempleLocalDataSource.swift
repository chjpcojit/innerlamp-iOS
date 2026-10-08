//
//  ILTempleLocalDataSource.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Core Data cache of the server temple catalog. Sits between `ILTempleRepositoryImpl` and
/// `CoreDataStack`; `ILCachedTempleMO` never leaves this folder.
///
/// Takes server DTOs in (the repository hands over exactly what it received) and gives Domain
/// entities out, mapped through `ILTempleMapper` — the same path as a fresh response.
nonisolated protocol ILTempleLocalDataSource {

    /// Page `page` of the "show all" list, or `nil` when it is not fully cached.
    func cachedTemplesPage(_ page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity>?

    func saveTemplesPage(_ dto: ILCatalogPageDTO<ILTempleSummaryDTO>) async throws

    /// The cached top list, in order. Empty when never fetched.
    func cachedTopTemples() async throws -> [ILTempleSummaryEntity]

    func saveTopTemples(_ dtos: [ILTempleSummaryDTO]) async throws

    /// The cached full profile, or `nil` when the detail of `id` was never fetched.
    func cachedTempleDetail(id: String) async throws -> ILTempleDetailEntity?

    func saveTempleDetail(_ dto: ILTempleDetailDTO) async throws

    /// Deletes the cached row of `id` (summary + detail). Used when the server no longer knows the
    /// temple; a list page that held it becomes "not fully cached" and is re-fetched.
    func removeTemple(id: String) async throws
}

nonisolated final class ILTempleLocalDataSourceImpl: ILTempleLocalDataSource {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func cachedTemplesPage(_ page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity>? {
        try await stack.performBackgroundTask { context in
            guard let rows = try ILCatalogCache.cachedPage(
                page, of: ILCachedTempleMO.self, key: .temples, in: context
            ) else { return nil }

            // Always `true`: the next page is served locally if cached, otherwise the server is
            // asked, and only the server's answer can end the list.
            return ILCatalogPageEntity(
                items: rows.map { ILTempleMapper.toDomain(Self.summaryDTO(of: $0)) },
                page: page,
                hasMore: true
            )
        }
    }

    func saveTemplesPage(_ dto: ILCatalogPageDTO<ILTempleSummaryDTO>) async throws {
        try await stack.performBackgroundTask { context in
            let rows = try ILCatalogCache.storePage(
                dto.page, pageSize: dto.pageSize, total: dto.total,
                ids: dto.items.map(\.id), of: ILCachedTempleMO.self, key: .temples, in: context
            )
            zip(rows, dto.items).forEach { Self.apply($1, to: $0) }
        }
    }

    func cachedTopTemples() async throws -> [ILTempleSummaryEntity] {
        try await stack.performBackgroundTask { context in
            try ILCatalogCache.topRows(ILCachedTempleMO.self, in: context)
                .map { ILTempleMapper.toDomain(Self.summaryDTO(of: $0)) }
        }
    }

    func saveTopTemples(_ dtos: [ILTempleSummaryDTO]) async throws {
        try await stack.performBackgroundTask { context in
            let rows = try ILCatalogCache.storeTop(ids: dtos.map(\.id), of: ILCachedTempleMO.self, in: context)
            zip(rows, dtos).forEach { Self.apply($1, to: $0) }
        }
    }

    func cachedTempleDetail(id: String) async throws -> ILTempleDetailEntity? {
        try await stack.performBackgroundTask { context in
            guard let payload = try ILCatalogCache.row(ILCachedTempleMO.self, id: id, in: context)?.detailPayload
            else { return nil }
            return ILTempleMapper.toDomain(try JSONDecoder().decode(ILTempleDetailDTO.self, from: payload))
        }
    }

    func saveTempleDetail(_ dto: ILTempleDetailDTO) async throws {
        let payload = try JSONEncoder().encode(dto)
        try await stack.performBackgroundTask { context in
            let row = try ILCatalogCache.upsertRow(ILCachedTempleMO.self, id: dto.id, in: context)
            Self.apply(dto.summary, to: row)
            row.detailPayload = payload
        }
    }

    func removeTemple(id: String) async throws {
        try await stack.performBackgroundTask { context in
            guard let row = try ILCatalogCache.row(ILCachedTempleMO.self, id: id, in: context) else { return }
            context.delete(row)
        }
    }

    // MARK: - Mapping

    private static func apply(_ dto: ILTempleSummaryDTO, to row: ILCachedTempleMO) {
        row.name = dto.name
        row.type = dto.type
        row.region = dto.region
        row.thumbnailURL = dto.thumbnailUrl
        row.imageURL = dto.imageUrl
        row.sect = dto.sect
        row.heritageRank = dto.heritageRank
        row.establishedYear = Int32(clamping: dto.establishedYear)
        row.latitude = dto.location.lat
        row.longitude = dto.location.lng
        row.address = dto.location.address
    }

    private static func summaryDTO(of row: ILCachedTempleMO) -> ILTempleSummaryDTO {
        ILTempleSummaryDTO(
            id: row.id,
            name: row.name,
            type: row.type,
            region: row.region,
            thumbnailUrl: row.thumbnailURL,
            imageUrl: row.imageURL,
            sect: row.sect,
            heritageRank: row.heritageRank,
            establishedYear: Int(row.establishedYear),
            location: ILTempleLocationDTO(lat: row.latitude, lng: row.longitude, address: row.address)
        )
    }
}
