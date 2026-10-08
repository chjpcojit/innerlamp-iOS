//
//  ILCalendarImageMapper.swift
//  InnerLamp
//

import Foundation

/// Converts the calendar-image DTO into a Domain entity, and a `Date` into the endpoint's `date`
/// query value.
nonisolated enum ILCalendarImageMapper {

    /// `nil` when `image_url` is blank — an image without a URL is no image at all.
    static func toDomain(_ dto: ILCalendarImageDTO) -> ILCalendarImageEntity? {
        guard let imageURL = nonEmpty(dto.imageUrl) else { return nil }
        return ILCalendarImageEntity(
            id: dto.id,
            imageURL: imageURL,
            author: dto.author.trimmingCharacters(in: .whitespacesAndNewlines),
            license: dto.license.trimmingCharacters(in: .whitespacesAndNewlines),
            licenseURL: dto.licenseUrl.flatMap(nonEmpty),
            sourceURL: dto.sourceUrl.flatMap(nonEmpty)
        )
    }

    /// `yyyy-MM-dd` from the Gregorian components of `date` in the device time zone — the same
    /// components the lunar computation uses, so the picture always matches the displayed day.
    static func dateQueryValue(for date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
