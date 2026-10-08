//
//  ILArticleDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of the article catalog — Data layer. Contract: `Docs/Specs/Article/design.md` →
/// "API contract" (confirmed by the backend team, 2026-09-30).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. The list wrappers
/// reuse `ILCatalogTopListDTO` / `ILCatalogPageDTO`. A DTO never escapes the Data layer.
nonisolated struct ILArticleSummaryDTO: Decodable, Sendable {
    let id: String
    let title: String
    let category: String
    let author: String
    let authorInitials: String
    /// Date-only `yyyy-MM-dd`; `null` for most articles.
    let publishedDate: String?
    let readMinutes: Int
    let summary: String
    /// Never `null` per contract.
    let tags: [String]
    /// Original publisher image (hotlink, usually 1200x630) — used for the detail hero.
    let imageUrl: String?
    /// Small square image hosted by the backend, for list cards; `null` when missing (key always
    /// present once the server is updated).
    let thumbnailUrl: String?
}

/// `Detail` = every `Summary` field plus the reading content below. Declared flat because the
/// server sends one flat object.
nonisolated struct ILArticleDetailDTO: Decodable, Sendable {
    let id: String
    let title: String
    let category: String
    let author: String
    let authorInitials: String
    let publishedDate: String?
    let readMinutes: Int
    let summary: String
    let tags: [String]
    let imageUrl: String?
    /// Plain text, one element per paragraph.
    let bodyParagraphs: [String]
    let quote: String
    let quoteSource: String
    let language: String
    let sourceName: String
    let sourceUrl: String
    let license: String
}
