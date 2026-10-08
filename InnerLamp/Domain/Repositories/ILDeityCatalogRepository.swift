//
//  ILDeityCatalogRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the Buddha / Bodhisattva catalog served by `/v1/deities*`,
/// cached in Core Data.
///
/// Separate from `ILDeityRepository`, which reads the catalog bundled with the app
/// (`phat_botat.json`) and answers the lunar-date / search queries the server has no endpoint for.
/// Both use the same ids.
///
/// Caching policy is the same as `ILTempleRepository`: the "show all" list
/// (`loadDeities(page:)`) is local-first, `loadTopDeities()` and `loadDeityDetail(id:)` are
/// network-first with a cached fallback when offline. Every failure is an `ILCatalogError`.
nonisolated protocol ILDeityCatalogRepository {

    /// The 10 featured deities (Buddhas first, then Bodhisattvas), in server order.
    func loadTopDeities() async throws -> [ILDeitySummaryEntity]

    /// One page (1-based, fixed server page size) of the full list (Buddhas then Bodhisattvas, `GET /v1/deities?page=N`), in server order.
    func loadDeities(page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity>

    /// The full profile of the Buddha or Bodhisattva with `id`.
    func loadDeityDetail(id: String) async throws -> ILDeityEntity
}
