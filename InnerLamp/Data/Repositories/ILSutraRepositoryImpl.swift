//
//  ILSutraRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server sutra catalog (`/v1/sutras*`). Network-only; maps every failure to `ILCatalogError`
/// (the same failure modes as the article / temple / deity catalogs).
nonisolated final class ILSutraRepositoryImpl: ILSutraRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadSutras(page: Int, filter: ILSutraFilter) async throws -> ILSutraPageEntity {
        guard page >= 1 else { throw ILCatalogError.invalidPage }

        do {
            let response = try await networkService.request(
                endpoint: SutrasPageEndpoint(page: page, filter: filter),
                responseType: ILCatalogPageDTO<ILSutraDTO>.self
            )
            return ILSutraPageEntity(
                items: response.items.map(ILSutraMapper.toDomain),
                page: response.page,
                totalCount: response.total,
                hasMore: !response.items.isEmpty && response.page < response.totalPages
            )
        } catch {
            throw ILCatalogError.from(error)
        }
    }

    func loadSutra(id: String) async throws -> ILSutraDetailSutraEntity {
        do {
            let response = try await networkService.request(
                endpoint: SutraDetailEndpoint(id: id),
                responseType: ILSutraDTO.self
            )
            return ILSutraMapper.toDetail(response)
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
