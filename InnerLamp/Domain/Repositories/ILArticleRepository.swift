//
//  ILArticleRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the "Phật pháp hay" article catalog served by `/v1/articles*`.
///
/// Network-only — unlike the temple / deity catalogs there is no local cache. Every failure is an
/// `ILCatalogError` (`.notFound` for an unknown id, `.offline` when the server cannot be reached,
/// `.invalidPage` for a page below 1, `.loadFailed` otherwise).
nonisolated protocol ILArticleRepository {

    /// The featured articles for Home (the server returns 5), in the server's curated order.
    func loadTopArticles() async throws -> [ILArticleSummaryEntity]

    /// One page (1-based, fixed server page size of 10) of the full article list, in server order.
    func loadArticles(page: Int) async throws -> ILArticlePageEntity

    /// The full article with `id`.
    func loadArticle(id: String) async throws -> ILArticleItemEntity
}
