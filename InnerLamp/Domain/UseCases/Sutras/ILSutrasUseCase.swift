//
//  ILSutrasUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSutrasUseCase {
    /// First page (`GET /v1/sutras?page=1`) narrowed by `filter` (chips + server-side keyword search).
    /// Throws `ILCatalogError` (`.offline` when the server is unreachable).
    func loadFirstPage(filter: ILSutraFilter) async throws -> ILSutrasEntity

    /// Appends the page after `entity.lastLoadedPage` and returns the merged entity. Returns
    /// `entity` unchanged when there is nothing more to load.
    func loadNextPage(after entity: ILSutrasEntity, filter: ILSutraFilter) async throws -> ILSutrasEntity
}

final class ILSutrasUseCaseImpl: ILSutrasUseCase {

    private let sutraRepository: ILSutraRepository

    init(sutraRepository: ILSutraRepository) {
        self.sutraRepository = sutraRepository
    }

    func loadFirstPage(filter: ILSutraFilter) async throws -> ILSutrasEntity {
        let page = try await sutraRepository.loadSutras(page: 1, filter: filter)
        return Self.makeEntity(appending: page, to: .empty)
    }

    func loadNextPage(after entity: ILSutrasEntity, filter: ILSutraFilter) async throws -> ILSutrasEntity {
        guard entity.hasMore else { return entity }
        let page = try await sutraRepository.loadSutras(page: entity.lastLoadedPage + 1, filter: filter)
        return Self.makeEntity(appending: page, to: entity)
    }

    private static func makeEntity(appending page: ILSutraPageEntity, to entity: ILSutrasEntity) -> ILSutrasEntity {
        // The server's slugs are unique, but never render the same row twice if a page overlaps
        // (e.g. the catalog changed between two requests).
        let knownIDs = Set(entity.sutras.map(\.id))
        let newRows = page.items.filter { !knownIDs.contains($0.id) }
        return ILSutrasEntity(
            sutras: entity.sutras + newRows,
            totalCount: page.totalCount,
            lastLoadedPage: page.page,
            hasMore: page.hasMore
        )
    }
}
