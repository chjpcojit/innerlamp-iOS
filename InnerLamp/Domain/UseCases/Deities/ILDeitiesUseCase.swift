//
//  ILDeitiesUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILDeitiesUseCase {
    /// Toàn bộ catalog "Phật & Bồ Tát" từ server — Chư Phật trước, rồi Chư Bồ Tát (server order).
    ///
    /// Read from every page of `GET /v1/deities`, which returns both types (no client-side filter).
    /// Paging follows the server's `page` / `total_pages` only. If the paged list fails, falls back
    /// to `GET /v1/deities/top` (a subset); throws `ILCatalogError` only when both fail.
    func loadDeities() async throws -> ILDeitiesEntity

    /// Lọc theo loại: `nil` = "Tất cả", `.buddha` = "Chư Phật", `.bodhisattva` = "Bồ Tát".
    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeitySummaryEntity]
}

final class ILDeitiesUseCaseImpl: ILDeitiesUseCase {

    /// Safety stop for the paging loop — guards against a server that keeps reporting more pages.
    private static let maxPages = 50

    private let deityCatalogRepository: ILDeityCatalogRepository

    init(deityCatalogRepository: ILDeityCatalogRepository) {
        self.deityCatalogRepository = deityCatalogRepository
    }

    func loadDeities() async throws -> ILDeitiesEntity {
        do {
            return ILDeitiesEntity(deities: Self.uniqued(try await loadAllPages()))
        } catch {
            #if DEBUG
            print("[Deities] paged catalog failed, falling back to top list: \(error)")
            #endif
            let top = try await deityCatalogRepository.loadTopDeities()
            return ILDeitiesEntity(deities: Self.uniqued(top))
        }
    }

    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeitySummaryEntity] {
        guard let kind else { return entity.deities }
        return entity.deities.filter { $0.kind == kind }
    }

    // MARK: - Private

    private func loadAllPages() async throws -> [ILDeitySummaryEntity] {
        var items: [ILDeitySummaryEntity] = []
        var page = 1
        while page <= Self.maxPages {
            let result = try await deityCatalogRepository.loadDeities(page: page)
            items += result.items
            guard result.hasMore else { break }
            page += 1
        }
        return items
    }

    /// Server-side inserts can shift rows across page boundaries (see `ILDeityCatalogRepository`),
    /// so keep the first occurrence of each id.
    private static func uniqued(_ deities: [ILDeitySummaryEntity]) -> [ILDeitySummaryEntity] {
        var seen = Set<String>()
        return deities.filter { seen.insert($0.id).inserted }
    }
}
