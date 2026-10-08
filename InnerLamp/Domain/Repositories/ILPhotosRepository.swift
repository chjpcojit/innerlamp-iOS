//
//  ILPhotosRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the "Ảnh chùa đẹp" gallery served by `GET /v1/gallery`.
///
/// Network-only (no local cache). Every failure is an `ILCatalogError` (`.offline` when the server
/// cannot be reached, `.invalidPage` for a page below 1, `.loadFailed` otherwise).
nonisolated protocol ILPhotosRepository {

    /// The featured photos for Home (the server returns 10), in the server's curated order.
    func loadTopPhotos() async throws -> [ILPhotosPhotoEntity]

    /// One page (1-based, fixed server page size of 20) in server order. `category == nil` loads
    /// every category.
    func loadPhotos(category: ILPhotosCategory?, page: Int) async throws -> ILPhotosPageEntity
}
