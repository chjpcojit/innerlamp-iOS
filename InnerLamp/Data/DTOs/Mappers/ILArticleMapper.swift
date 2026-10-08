//
//  ILArticleMapper.swift
//  InnerLamp
//

import Foundation

/// Converts article DTOs into Domain entities, field for field.
nonisolated enum ILArticleMapper {

    static func toDomain(_ dto: ILArticleSummaryDTO) -> ILArticleSummaryEntity {
        ILArticleSummaryEntity(
            id: dto.id,
            category: dto.category,
            title: dto.title,
            author: dto.author,
            authorInitials: dto.authorInitials,
            readMinutes: dto.readMinutes,
            publishedDate: date(from: dto.publishedDate),
            imageURL: nonEmpty(dto.imageUrl),
            thumbnailURL: nonEmpty(dto.thumbnailUrl)
        )
    }

    static func toDomain(_ dto: ILArticleDetailDTO) -> ILArticleItemEntity {
        ILArticleItemEntity(
            id: dto.id,
            category: dto.category,
            title: dto.title,
            author: dto.author,
            authorInitials: dto.authorInitials,
            publishedDate: date(from: dto.publishedDate),
            readMinutes: dto.readMinutes,
            bodyParagraphs: dto.bodyParagraphs,
            quote: dto.quote,
            quoteSource: dto.quoteSource,
            sourceName: dto.sourceName,
            sourceURL: sourceURL(from: dto.sourceUrl),
            imageURL: nonEmpty(dto.imageUrl)
        )
    }

    /// Parses the server's date-only `yyyy-MM-dd`. A malformed value is treated as "no date"
    /// instead of failing the whole page — the date is decoration, not content.
    static func date(from raw: String?) -> Date? {
        guard let raw = nonEmpty(raw) else { return nil }
        return dateFormatter.date(from: raw)
    }

    /// Only an absolute `http(s)` link is kept — the value is opened in the browser.
    private static func sourceURL(from raw: String) -> String? {
        guard let value = nonEmpty(raw),
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else { return nil }
        return value
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    /// GMT + Gregorian + POSIX locale, so a date-only value never shifts a day with the device
    /// time zone. `ILArticleViewModel` formats with the same calendar / time zone.
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
