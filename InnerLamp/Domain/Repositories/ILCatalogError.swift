//
//  ILCatalogError.swift
//  InnerLamp
//

import Foundation

/// Failures surfaced by the server-backed catalog repositories (`ILTempleRepository`,
/// `ILDeityCatalogRepository`). Shared because both catalogs have exactly the same failure modes.
///
/// Mirrors `ILDeityError`: carries the underlying error where useful but renders a stable,
/// user-facing message via `errorDescription`.
nonisolated enum ILCatalogError: Error, LocalizedError {
    /// The server rejected the page number (`INVALID_PAGE`) — a caller bug, pages start at 1.
    case invalidPage
    /// No temple / deity / article / sutra with the requested id (`TEMPLE_NOT_FOUND` /
    /// `DEITY_NOT_FOUND` / `ARTICLE_NOT_FOUND` / `SUTRA_NOT_FOUND`).
    case notFound
    /// The server could not be reached and nothing usable is cached.
    case offline
    /// `429 RATE_LIMITED` (per IP, public routes): try again after `retryAfterSeconds` when known.
    case rateLimited(retryAfterSeconds: Int?)
    /// Anything else — server error, malformed payload, Core Data failure.
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidPage, .loadFailed:
            return "catalog.error.loadFailed".localized
        case .notFound:
            return "catalog.error.notFound".localized
        case .offline:
            return "catalog.error.offline".localized
        case .rateLimited:
            return "catalog.error.rateLimited".localized
        }
    }
}
