//
//  ILSutraRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the sutra / verse / mantra catalog served by `/v1/sutras*`.
///
/// Network-only. Every failure is an `ILCatalogError` (`.notFound` for an unknown id, `.offline`
/// when the server cannot be reached, `.invalidPage` for a page below 1, `.loadFailed` otherwise).
nonisolated protocol ILSutraRepository {

    /// One page (1-based, fixed server page size of 20) of the list, narrowed by `filter`.
    func loadSutras(page: Int, filter: ILSutraFilter) async throws -> ILSutraPageEntity

    /// The sutra with `id`, including its translation sources and table of contents.
    func loadSutra(id: String) async throws -> ILSutraDetailSutraEntity
}
