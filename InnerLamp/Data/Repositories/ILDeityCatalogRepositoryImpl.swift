//
//  ILDeityCatalogRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server Buddha / Bodhisattva catalog + Core Data cache. Same policy and structure as
/// `ILTempleRepositoryImpl`.
nonisolated final class ILDeityCatalogRepositoryImpl: ILDeityCatalogRepository {

    private let networkService: NetworkService
    private let localDataSource: ILDeityCatalogLocalDataSource

    init(networkService: NetworkService, localDataSource: ILDeityCatalogLocalDataSource) {
        self.networkService = networkService
        self.localDataSource = localDataSource
    }

    func loadTopDeities() async throws -> [ILDeitySummaryEntity] {
        let response: ILCatalogTopListDTO<ILDeitySummaryDTO>
        do {
            response = try await networkService.request(
                endpoint: TopDeitiesEndpoint(),
                responseType: ILCatalogTopListDTO<ILDeitySummaryDTO>.self
            )
        } catch {
            // A cache read failure must not hide the network error that got us here.
            let cached = (try? await localDataSource.cachedTopDeities()) ?? []
            guard !cached.isEmpty else { throw ILCatalogError.from(error) }
            return cached
        }
        await ILCatalogCacheWrite.bestEffort("top deities") {
            try await localDataSource.saveTopDeities(response.items)
        }
        return response.items.map(ILDeityMapper.toDomain)
    }

    func loadDeities(page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity> {
        guard page >= 1 else { throw ILCatalogError.invalidPage }

        if let cached = try await wrapLocal({ try await localDataSource.cachedDeitiesPage(page) }) {
            return cached
        }

        let response: ILCatalogPageDTO<ILDeitySummaryDTO>
        do {
            response = try await networkService.request(
                endpoint: DeitiesPageEndpoint(page: page),
                responseType: ILCatalogPageDTO<ILDeitySummaryDTO>.self
            )
        } catch {
            throw ILCatalogError.from(error)
        }
        await ILCatalogCacheWrite.bestEffort("deities page \(page)") {
            try await localDataSource.saveDeitiesPage(response)
        }
        return ILCatalogPageEntity(
            items: response.items.map(ILDeityMapper.toDomain),
            page: response.page,
            hasMore: !response.items.isEmpty && response.page < response.totalPages
        )
    }

    func loadDeityDetail(id: String) async throws -> ILDeityEntity {
        let response: ILDeityDTO
        do {
            response = try await networkService.request(
                endpoint: DeityDetailEndpoint(id: id),
                responseType: ILDeityDTO.self
            )
        } catch {
            let mapped = ILCatalogError.from(error)
            if case .notFound = mapped { throw mapped }
            guard let cached = try? await localDataSource.cachedDeityDetail(id: id) else { throw mapped }
            return cached
        }
        await ILCatalogCacheWrite.bestEffort("deity detail") {
            try await localDataSource.saveDeityDetail(response)
        }
        return ILDeityMapper.toDomain(response)
    }

    private func wrapLocal<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw ILCatalogError.loadFailed(error)
        }
    }
}
