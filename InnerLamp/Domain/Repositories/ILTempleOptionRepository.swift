//
//  ILTempleOptionRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the light, searchable temple list (`GET /v1/temples/options`) used by pickers.
///
/// Network only — the endpoint sends no cache headers and the result depends on `query`, so
/// nothing is cached locally. Every failure is an `ILCatalogError`.
nonisolated protocol ILTempleOptionRepository {

    /// One page (1-based, fixed server page size of 100) in server order.
    ///
    /// - Parameter query: server-side search over the temple name (contains, case- and
    ///   diacritic-insensitive). `nil` / blank = no filter.
    /// - Returns: the page; `hasMore == false` once `page >= total_pages` or the page is empty.
    func loadTempleOptions(query: String?, page: Int) async throws -> ILCatalogPageEntity<ILTempleOptionEntity>
}
