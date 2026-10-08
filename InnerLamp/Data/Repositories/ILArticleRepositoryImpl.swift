//
//  ILArticleRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server article catalog (`/v1/articles*`). Network-only; maps every failure to `ILCatalogError`
/// (the same failure modes as the temple / deity catalogs).
nonisolated final class ILArticleRepositoryImpl: ILArticleRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadTopArticles() async throws -> [ILArticleSummaryEntity] {
        do {
            let response = try await networkService.request(
                endpoint: TopArticlesEndpoint(),
                responseType: ILCatalogTopListDTO<ILArticleSummaryDTO>.self
            )
            return response.items.map(ILArticleMapper.toDomain)
        } catch {
            throw ILCatalogError.from(error)
        }
    }

    func loadArticles(page: Int) async throws -> ILArticlePageEntity {
        guard page >= 1 else { throw ILCatalogError.invalidPage }

        do {
            let response = try await networkService.request(
                endpoint: ArticlesPageEndpoint(page: page),
                responseType: ILCatalogPageDTO<ILArticleSummaryDTO>.self
            )
            return ILArticlePageEntity(
                items: response.items.map(ILArticleMapper.toDomain),
                page: response.page,
                totalCount: response.total,
                hasMore: !response.items.isEmpty && response.page < response.totalPages
            )
        } catch {
            throw ILCatalogError.from(error)
        }
    }

    func loadArticle(id: String) async throws -> ILArticleItemEntity {
        do {
            let response = try await networkService.request(
                endpoint: ArticleDetailEndpoint(id: id),
                responseType: ILArticleDetailDTO.self
            )
            return ILArticleMapper.toDomain(response)
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
