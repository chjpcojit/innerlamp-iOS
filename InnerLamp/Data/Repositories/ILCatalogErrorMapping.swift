//
//  ILCatalogErrorMapping.swift
//  InnerLamp
//

import Foundation

nonisolated extension ILCatalogError {

    /// Maps a transport / storage failure to the Domain error. Branches on the server's
    /// `error.code`, never on its message.
    static func from(_ error: Error) -> ILCatalogError {
        if let catalogError = error as? ILCatalogError {
            return catalogError
        }
        guard let networkError = error as? NetworkError else {
            return .loadFailed(error)
        }
        switch networkError {
        case .apiError(let code, _, _, _) where code == "INVALID_PAGE":
            return .invalidPage
        case .apiError(let code, _, _, _) where code == "TEMPLE_NOT_FOUND" || code == "DEITY_NOT_FOUND"
            || code == "ARTICLE_NOT_FOUND" || code == "SUTRA_NOT_FOUND"
            || code == "ADMINISTRATIVE_UNIT_NOT_FOUND":
            return .notFound
        case .apiError(let code, _, _, let details) where code == "RATE_LIMITED":
            return .rateLimited(retryAfterSeconds: details?["retry_after_seconds"]?.value as? Int)
        case .noInternetConnection, .timeout:
            return .offline
        default:
            return .loadFailed(networkError)
        }
    }
}

/// Writes a fresh server response into the Core Data cache without letting a storage failure
/// discard that response: the caller already has the data, the cache only matters for offline use.
nonisolated enum ILCatalogCacheWrite {

    static func bestEffort(_ label: String, _ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch {
            // Non-fatal by design, but never silent: the next offline read would come up empty.
            #if DEBUG
            print("[Catalog] cache write failed (\(label)): \(error)")
            #endif
        }
    }
}
