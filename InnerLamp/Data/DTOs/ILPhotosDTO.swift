//
//  ILPhotosDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of one gallery item (`GET /v1/gallery`) — Data layer. Contract:
/// `Docs/Specs/Photos/design.md` → "API contract" (confirmed by the backend team, 2026-10-06).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. The list wrapper
/// reuses `ILCatalogPageDTO`. A DTO never escapes the Data layer.
nonisolated struct ILPhotosSummaryDTO: Decodable, Sendable {
    let id: String
    /// `CHUA` / `TUONG_PHAT` / `THIEN` / `LE_HOI`.
    let type: String
    let title: String
    let location: String
    let thumbnailUrl: String
    let imageUrl: String
}
