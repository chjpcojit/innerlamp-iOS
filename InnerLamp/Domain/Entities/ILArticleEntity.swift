//
//  ILArticleEntity.swift
//  InnerLamp
//

import Foundation

/// One "Phật pháp hay" article as listed on Home / in the All-articles list — the server's
/// `Summary` object without the body. Domain layer only; never a DTO.
nonisolated struct ILArticleSummaryEntity: Equatable, Identifiable {
    /// Stable server slug (e.g. `vipassana-nghe-thuat-song`).
    let id: String
    let category: String
    let title: String
    let author: String
    /// Editorial avatar initials ("MĐ", "IL") — not derivable from `author`.
    let authorInitials: String
    let readMinutes: Int
    /// Date-only value (no time of day) in the Gregorian calendar, GMT; `nil` when the server has
    /// no date for the article.
    let publishedDate: Date?
    let imageURL: String?
    /// Small backend-hosted image for list cards; `nil` → callers fall back to `imageURL`.
    var thumbnailURL: String? = nil
}

/// 1 full article for the Article detail screen — the server's `Detail` object.
nonisolated struct ILArticleItemEntity: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    let authorInitials: String
    /// Date-only value (Gregorian, GMT); `nil` when the server has no date for the article.
    let publishedDate: Date?
    /// Reading minutes; the "N phút đọc" string is formatted by `ILArticleViewModel`.
    let readMinutes: Int
    /// Plain-text paragraphs, one element per paragraph (no HTML / markdown).
    let bodyParagraphs: [String]
    let quote: String
    let quoteSource: String
    /// Name of the press outlet the article summarises (e.g. "Báo Giác Ngộ").
    let sourceName: String
    /// Link to the original article; `nil` when the server value is empty or not a URL.
    let sourceURL: String?
    /// Raw server image URL; `nil` keeps the hero placeholder.
    let imageURL: String?
}

/// One page of the All-articles list. `hasMore == false` means the caller must stop requesting
/// further pages (`page >= total_pages`, or the server returned an empty page).
nonisolated struct ILArticlePageEntity: Equatable {
    let items: [ILArticleSummaryEntity]
    let page: Int
    let totalCount: Int
    let hasMore: Bool
}

/// Pure business entity for the Article detail screen — Domain layer only.
///
/// Holds the article being read, the "Đọc tiếp" candidates and the in-memory set of saved ids.
/// Labels ("Lưu bài"/"Đã lưu"), the "N phút đọc" string and the formatted date are UI state on
/// `ILArticleStateModel`.
struct ILArticleEntity: Equatable {
    var currentArticleID: String = ""
    /// `nil` until `GET /v1/articles/{id}` succeeds.
    var article: ILArticleItemEntity?
    /// Up to 2 other articles suggested after the current one (see `ILArticleUseCase`).
    var nextArticles: [ILArticleSummaryEntity] = []
    /// Saved articles — in-memory only (no backend endpoint, no "Saved" screen yet).
    var savedArticleIDs: Set<String> = []

    static let empty = ILArticleEntity()
}
