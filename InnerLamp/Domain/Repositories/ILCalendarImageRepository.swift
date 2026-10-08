//
//  ILCalendarImageRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the picture of a solar date served by `GET /v1/calendar/image`.
///
/// Network-only (no local cache; the image bytes are cached by `ILRemoteImageView` / `URLSession`).
/// Every failure is an `ILCatalogError` (`.offline` when the server cannot be reached,
/// `.loadFailed` otherwise).
nonisolated protocol ILCalendarImageRepository {

    /// The image for the Gregorian day/month/year of `date` (device time zone). The same date always
    /// yields the same image.
    func loadImage(for date: Date) async throws -> ILCalendarImageEntity
}
