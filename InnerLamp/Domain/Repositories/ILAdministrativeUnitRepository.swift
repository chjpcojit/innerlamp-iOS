//
//  ILAdministrativeUnitRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the administrative-unit metadata (province -> ward, 2-level system since 01/07/2025)
/// from the server. Shared by every screen that needs an address picker or a
/// `province_code` / `ward_code`.
///
/// Network only. The server answers with `Cache-Control: public, max-age=86400` and the app's
/// `URLSession` honours it, so repeat calls within 24h are served by the system HTTP cache
/// (the endpoints are rate limited to 60 requests/minute/IP). Every failure is an
/// `ILCatalogError`.
nonisolated protocol ILAdministrativeUnitRepository {

    /// All provinces / cities, sorted by Vietnamese alphabet of `name`. One response, no paging.
    func loadProvinces() async throws -> [ILProvinceEntity]

    /// All wards of one province in server order. One response, no paging (at most 168 rows).
    ///
    /// - Parameter query: server-side search over the ward full name (contains, case- and
    ///   diacritic-insensitive). `nil` / blank = no filter.
    /// - Throws: `ILCatalogError.notFound` when `provinceCode` is not a code of the 2-level system.
    func loadWards(provinceCode: String, query: String?) async throws -> [ILWardEntity]
}
