//
//  ILArticleUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILArticleUseCase {
    /// Entity for `articleID` with nothing loaded yet — the article is filled by `loadArticle(id:)`.
    func getInitialState(articleID: String) -> ILArticleEntity

    /// Full article from `GET /v1/articles/{id}`. Throws `ILCatalogError` — `.notFound` for an
    /// unknown id, `.offline` when the server is unreachable.
    func loadArticle(id: String) async throws -> ILArticleItemEntity

    /// Up to 2 "Đọc tiếp" articles other than `id`, taken from `GET /v1/articles/top` (the API has
    /// no related-articles field). Best effort: a failure yields `[]` so it never blocks reading.
    func loadNextArticles(excluding id: String) async -> [ILArticleSummaryEntity]

    /// Toggles the saved state of `id` — pure in-memory, not persisted.
    func toggleSave(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity
}

final class ILArticleUseCaseImpl: ILArticleUseCase {

    private static let nextArticleCount = 2

    private let articleRepository: ILArticleRepository

    init(articleRepository: ILArticleRepository) {
        self.articleRepository = articleRepository
    }

    func getInitialState(articleID: String) -> ILArticleEntity {
        ILArticleEntity(currentArticleID: articleID)
    }

    func loadArticle(id: String) async throws -> ILArticleItemEntity {
        try await articleRepository.loadArticle(id: id)
    }

    func loadNextArticles(excluding id: String) async -> [ILArticleSummaryEntity] {
        do {
            let top = try await articleRepository.loadTopArticles()
            return Array(top.filter { $0.id != id }.prefix(Self.nextArticleCount))
        } catch {
            #if DEBUG
            print("[Article] loadNextArticles failed: \(error)")
            #endif
            return []
        }
    }

    func toggleSave(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity {
        var updated = entity
        if updated.savedArticleIDs.contains(id) {
            updated.savedArticleIDs.remove(id)
        } else {
            updated.savedArticleIDs.insert(id)
        }
        return updated
    }
}
