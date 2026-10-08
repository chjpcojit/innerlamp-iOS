//
//  ILTempleRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the temple (chùa) catalog served by `/v1/temples*`, cached in Core Data.
///
/// Caching policy:
/// - `loadTemples(page:)` ("show all" list) is **local-first**: a page already cached is served
///   from Core Data without a network call (`hasMore == true`, so the caller asks for the next
///   page). Only when the local cache runs out is the server asked; returned rows are stored, and
///   the server alone ends the list — an empty page or `page >= total_pages` gives
///   `hasMore == false`, and the caller stops.
/// - `loadTopTemples()` and `loadTempleDetail(id:)` are **network-first**: the fresh response is
///   stored, and the cached copy is only returned when the server cannot be reached.
///
/// Every failure is an `ILCatalogError`.
nonisolated protocol ILTempleRepository {

    /// The 10 featured temples, in server order.
    func loadTopTemples() async throws -> [ILTempleSummaryEntity]

    /// One page (1-based, fixed server page size) of the full temple list, in server order.
    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity>

    /// The full profile of the temple with `id`.
    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity
}
