//
//  ILArticlesUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILArticlesUseCase {
    /// First page (`GET /v1/articles?page=1`) of the article list.
    /// Throws `ILCatalogError` (`.offline` when the server is unreachable).
    func loadFirstPage() async throws -> ILArticlesEntity

    /// Appends the page after `entity.lastLoadedPage` and returns the merged entity. Returns
    /// `entity` unchanged when there is nothing more to load.
    func loadNextPage(after entity: ILArticlesEntity) async throws -> ILArticlesEntity
}

final class ILArticlesUseCaseImpl: ILArticlesUseCase {

    private let articleRepository: ILArticleRepository

    init(articleRepository: ILArticleRepository) {
        self.articleRepository = articleRepository
    }

    func loadFirstPage() async throws -> ILArticlesEntity {
        let page = try await articleRepository.loadArticles(page: 1)
        return Self.makeEntity(appending: page, to: .empty)
    }

    func loadNextPage(after entity: ILArticlesEntity) async throws -> ILArticlesEntity {
        guard entity.hasMore else { return entity }
        let page = try await articleRepository.loadArticles(page: entity.lastLoadedPage + 1)
        return Self.makeEntity(appending: page, to: entity)
    }

    private static func makeEntity(appending page: ILArticlePageEntity, to entity: ILArticlesEntity) -> ILArticlesEntity {
        // The server's slugs are unique, but never render the same row twice if a page overlaps
        // (e.g. the catalog changed between two requests).
        let knownIDs = Set(entity.articles.map(\.id))
        let newRows = page.items
            .filter { !knownIDs.contains($0.id) }
            .map {
                ILArticlesItemEntity(
                    id: $0.id,
                    category: $0.category,
                    title: $0.title,
                    author: $0.author,
                    readMinutes: $0.readMinutes,
                    thumbnailURL: $0.thumbnailURL ?? $0.imageURL
                )
            }
        let articles = entity.articles + newRows
        return ILArticlesEntity(
            articles: articles,
            loadedCount: articles.count,
            totalCount: page.totalCount,
            lastLoadedPage: page.page,
            hasMore: page.hasMore
        )
    }
}
