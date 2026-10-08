//
//  ILPhotosUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILPhotosUseCase {
    /// First page (`GET /v1/gallery?page=1`) for `category` (`nil` = Tất cả).
    /// Throws `ILCatalogError` (`.offline` when the server is unreachable).
    func loadFirstPage(category: ILPhotosCategory?) async throws -> ILPhotosEntity

    /// Appends the page after `entity.lastLoadedPage` for the entity's category and returns the
    /// merged entity. Returns `entity` unchanged when there is nothing more to load.
    func loadNextPage(after entity: ILPhotosEntity) async throws -> ILPhotosEntity
}

final class ILPhotosUseCaseImpl: ILPhotosUseCase {

    private let photosRepository: ILPhotosRepository

    init(photosRepository: ILPhotosRepository) {
        self.photosRepository = photosRepository
    }

    func loadFirstPage(category: ILPhotosCategory?) async throws -> ILPhotosEntity {
        let page = try await photosRepository.loadPhotos(category: category, page: 1)
        return Self.makeEntity(appending: page, to: ILPhotosEntity(selectedCategory: category))
    }

    func loadNextPage(after entity: ILPhotosEntity) async throws -> ILPhotosEntity {
        guard entity.hasMore else { return entity }
        let page = try await photosRepository.loadPhotos(
            category: entity.selectedCategory,
            page: entity.lastLoadedPage + 1
        )
        return Self.makeEntity(appending: page, to: entity)
    }

    private static func makeEntity(appending page: ILPhotosPageEntity, to entity: ILPhotosEntity) -> ILPhotosEntity {
        // Never render the same photo twice if a page overlaps (the catalog changed between two
        // requests).
        let knownIDs = Set(entity.photos.map(\.id))
        var updated = entity
        updated.photos += page.items.filter { !knownIDs.contains($0.id) }
        updated.totalCount = page.totalCount
        updated.lastLoadedPage = page.page
        updated.hasMore = page.hasMore
        return updated
    }
}
