//
//  ILDeityRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the "Buddhas & Bodhisattvas" catalog.
///
/// Entity in, entity out. No DTO, no `CoreData` import — the storage shape is a Data-layer concern.
/// Read-only: the catalog is seeded once from the bundled `phat_botat.json` by the data source.
/// Every list result keeps the catalog order (Buddhas first, then Bodhisattvas, as in the file).
nonisolated protocol ILDeityRepository {

    /// The whole catalog.
    func loadAll() async throws -> [ILDeityEntity]

    /// The deity with `id`, or `nil` when the catalog has none.
    func loadDeity(id: String) async throws -> ILDeityEntity?

    /// Only Buddhas, or only Bodhisattvas.
    func loadDeities(kind: ILDeityKind) async throws -> [ILDeityEntity]

    /// Deities with a memorial day (ngày vía) on the given lunar date.
    func loadDeities(lunarDay: Int, lunarMonth: Int) async throws -> [ILDeityEntity]

    /// Deities whose name (Vietnamese / Sanskrit / Chinese) or honorific title contains `query`,
    /// ignoring case and diacritics. An empty query returns the whole catalog.
    ///
    /// Note: `Đ`/`đ` is a distinct letter, not a diacritic, so "dia tang" does not match "Địa Tạng".
    func searchDeities(query: String) async throws -> [ILDeityEntity]
}

/// Failures surfaced by `ILDeityRepository`.
///
/// Mirrors `ILBuddhistEventError`: carries the underlying error but renders a stable, user-facing
/// message via `errorDescription`.
enum ILDeityError: Error, LocalizedError {
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "deity.error.loadFailed".localized
        }
    }
}
