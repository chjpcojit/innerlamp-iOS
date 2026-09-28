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
}

/// Pure business entity for the "All articles" screen — Domain layer only.
///
/// Holds the loaded article rows plus the pagination position (`loadedCount` / `totalCount`) used
/// to drive infinite scroll. UI-only state (the `isLoadingMore` flag, the "N / M bài" subtitle,
/// the "… phút đọc" string) lives on `ILArticlesStateModel` instead — see
/// `references/data_layer_boundaries.md`.
struct ILArticlesEntity: Equatable {
    var articles: [ILArticlesItemEntity] = []
    /// Number of articles revealed so far.
    var loadedCount: Int = 0
    /// Total articles in the (future) server catalog.
    var totalCount: Int = 0

    var hasMore: Bool { loadedCount < totalCount }

    static let empty = ILArticlesEntity()
}
