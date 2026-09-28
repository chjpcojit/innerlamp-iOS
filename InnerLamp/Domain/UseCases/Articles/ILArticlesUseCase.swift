//
//  ILArticlesUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILArticlesUseCase {
    /// First page of the article list (design handoff: start with the first 20 of 60 articles —
    /// currently backed by a static catalog, see TODO in the impl).
    func getInitialState() -> ILArticlesEntity

    /// Loads the next page of articles. Out of scope for il-screen-builder — the real
    /// implementation would call `NetworkService` (article catalog, see README design handoff
    /// "Data cần API"), so it is left as a one-line-TODO stub with an `async throws` signature.
    func loadMoreArticles() async throws
}

final class ILArticlesUseCaseImpl: ILArticlesUseCase {

    /// Page size and total match the design handoff "Tất cả bài viết" screen (20 articles per
    /// page, 60 total). Replace with values returned by the article API once it exists.
    static let pageSize = 20
    static let totalCount = 60

    // TODO: when a real article API exists, source the catalog (and `totalCount`) from
    // networkService instead of the static catalog below.
    init() {}

    func getInitialState() -> ILArticlesEntity {
        let catalog = Self.makeArticleCatalog()
        return ILArticlesEntity(
            articles: catalog,
            loadedCount: catalog.count,
            totalCount: Self.totalCount
        )
    }

    // Out of scope for this skill — do NOT call NetworkService here, do NOT fabricate a response.
    // Keep the signature, reduce the body to a one-line TODO print.
    func loadMoreArticles() async throws {
        print("TODO: implement loadMoreArticles — network/repository call, not built by il-screen-builder")
    }

    // MARK: - Catalog

    /// Static catalog of 5 articles matching `ILArticleUseCaseImpl` (same `art-1` → `art-5` ids,
    /// so tapping a row opens the correct Article detail screen). Display content is localized,
    /// same approach as `ILHomeUseCaseImpl` / `ILArticleUseCaseImpl`.
    private static func makeArticleCatalog() -> [ILArticlesItemEntity] {
        (0..<5).map { index in
            let prefix = "article.article.\(index)"
            return ILArticlesItemEntity(
                id: "art-\(index + 1)",
                category: "\(prefix).category".localized,
                title: "\(prefix).title".localized,
                author: "\(prefix).author".localized,
                readMinutes: Self.readMinutes[index]
            )
        }
    }

    /// Reading minutes per article (matches `ILArticleUseCaseImpl.readMinutes`).
    private static let readMinutes = [6, 4, 5, 5, 7]
}
