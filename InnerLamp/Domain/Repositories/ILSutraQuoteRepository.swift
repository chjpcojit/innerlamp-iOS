//
//  ILSutraQuoteRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the catalog of sutra quotes.
///
/// Entity in, entity out. No DTO, no `CoreData` import. The catalog is static content seeded from
/// the bundled JSON, so there is no write API beyond `seedIfNeeded()`.
///
/// Positions are 0-based offsets into the catalog sorted by `ILSutraQuoteEntity.id` ascending, so
/// `quote(at:)` can fetch a single row instead of loading the whole catalog.
nonisolated protocol ILSutraQuoteRepository {

    /// Loads the bundled catalog into the store when rows are missing. Idempotent.
    func seedIfNeeded() async throws

    /// Number of stored quotes (seeding first if needed).
    func count() async throws -> Int

    /// The quote at `index` in id order, or `nil` when `index` is out of range.
    func quote(at index: Int) async throws -> ILSutraQuoteEntity?

    /// Every stored quote, sorted by id.
    func loadAll() async throws -> [ILSutraQuoteEntity]
}

/// Failures surfaced by `ILSutraQuoteRepository`.
enum ILSutraQuoteError: Error, LocalizedError {
    /// The bundled JSON is missing or could not be decoded / inserted.
    case seedFailed(Error)
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .seedFailed:
            return "sutraQuote.error.seedFailed".localized
        case .loadFailed:
            return "sutraQuote.error.loadFailed".localized
        }
    }
}
