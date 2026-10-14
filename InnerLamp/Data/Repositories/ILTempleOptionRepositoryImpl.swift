//
//  ILTempleOptionRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Network-only reader of `GET /v1/temples/options`; maps every failure to `ILCatalogError`.
nonisolated final class ILTempleOptionRepositoryImpl: ILTempleOptionRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadTempleOptions(query: String?, page: Int) async throws -> ILCatalogPageEntity<ILTempleOptionEntity> {
        guard page >= 1 else { throw ILCatalogError.invalidPage }
        do {
            let response = try await networkService.request(
                endpoint: TempleOptionsEndpoint(page: page, query: query),
                responseType: ILCatalogPageDTO<ILTempleOptionDTO>.self
            )
            return ILTempleOptionMapper.toDomain(response)
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
