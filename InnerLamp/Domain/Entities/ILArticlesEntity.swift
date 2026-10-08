//
//  ILArticlesEntity.swift
//  InnerLamp
//

import Foundation

/// One article row in the "All articles" list — only the fields the list card needs (category,
/// title, author, reading minutes). The full body/quote live on `ILArticleItemEntity` (the
/// Article detail screen) and are deliberately not duplicated here.
struct ILArticlesItemEntity: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    let readMinutes: Int
    /// Raw server thumbnail URL (`thumbnail_url`, falling back to `image_url`); `nil` when the
    /// article has no image.
    var thumbnailURL: String? = nil
}

/// Pure business entity for the "All articles" screen — Domain layer only.
///
/// Holds the loaded article rows plus the pagination position used to drive infinite scroll.
/// UI-only state (the `isLoadingMore` flag, the "N / M bài" subtitle, the "… phút đọc" string)
/// lives on `ILArticlesStateModel` instead.
struct ILArticlesEntity: Equatable {
    var articles: [ILArticlesItemEntity] = []
    /// Number of articles loaded so far.
    var loadedCount: Int = 0
    /// Total articles on the server (`total` of the paged response).
    var totalCount: Int = 0
    /// Last page fetched (1-based); `0` before the first page.
    var lastLoadedPage: Int = 0
    /// `false` once the server's last page was loaded, or a page came back empty.
    var hasMore: Bool = false

    static let empty = ILArticlesEntity()
}
