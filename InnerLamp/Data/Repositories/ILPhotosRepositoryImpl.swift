//
//  ILPhotosRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server gallery (`/v1/gallery`). Network-only; maps every failure to `ILCatalogError` (the same
/// failure modes as the article / temple / deity catalogs).
nonisolated final class ILPhotosRepositoryImpl: ILPhotosRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadTopPhotos() async throws -> [ILPhotosPhotoEntity] {
        do {
            let response = try await networkService.request(
                endpoint: TopPhotosEndpoint(),
                responseType: ILCatalogTopListDTO<ILPhotosSummaryDTO>.self
            )
            return response.items.compactMap(ILPhotosMapper.toDomain)
        } catch {
            throw ILCatalogError.from(error)
        }
    }

    func loadPhotos(category: ILPhotosCategory?, page: Int) async throws -> ILPhotosPageEntity {
        guard page >= 1 else { throw ILCatalogError.invalidPage }

        do {
            let response = try await networkService.request(
                endpoint: PhotosPageEndpoint(page: page, type: category.map(ILPhotosMapper.type(for:))),
                responseType: ILCatalogPageDTO<ILPhotosSummaryDTO>.self
            )
            return ILPhotosPageEntity(
                items: response.items.compactMap(ILPhotosMapper.toDomain),
                page: response.page,
                totalCount: response.total,
                // Judged on the raw page: a page whose items were all dropped is not "the end".
                hasMore: !response.items.isEmpty && response.page < response.totalPages
            )
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
