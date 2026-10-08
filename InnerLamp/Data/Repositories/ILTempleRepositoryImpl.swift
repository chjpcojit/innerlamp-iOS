//
//  ILTempleRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server temple catalog + Core Data cache. The caching policy is documented on
/// `ILTempleRepository`; this type decides between the two sources and maps every failure to
/// `ILCatalogError`.
nonisolated final class ILTempleRepositoryImpl: ILTempleRepository {

    private let networkService: NetworkService
    private let localDataSource: ILTempleLocalDataSource

    init(networkService: NetworkService, localDataSource: ILTempleLocalDataSource) {
        self.networkService = networkService
        self.localDataSource = localDataSource
    }

    func loadTopTemples() async throws -> [ILTempleSummaryEntity] {
        let response: ILCatalogTopListDTO<ILTempleSummaryDTO>
        do {
            response = try await networkService.request(
                endpoint: TopTemplesEndpoint(),
                responseType: ILCatalogTopListDTO<ILTempleSummaryDTO>.self
            )
        } catch {
            // A cache read failure must not hide the network error that got us here.
            let cached = (try? await localDataSource.cachedTopTemples()) ?? []
            guard !cached.isEmpty else { throw ILCatalogError.from(error) }
            return cached
        }
        await ILCatalogCacheWrite.bestEffort("top temples") {
            try await localDataSource.saveTopTemples(response.items)
        }
        return response.items.map(ILTempleMapper.toDomain)
    }

    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity> {
        guard page >= 1 else { throw ILCatalogError.invalidPage }

        if let cached = try await wrapLocal({ try await localDataSource.cachedTemplesPage(page) }) {
            return cached
        }

        let response: ILCatalogPageDTO<ILTempleSummaryDTO>
        do {
            response = try await networkService.request(
                endpoint: TemplesPageEndpoint(page: page),
                responseType: ILCatalogPageDTO<ILTempleSummaryDTO>.self
            )
        } catch {
            throw ILCatalogError.from(error)
        }
        await ILCatalogCacheWrite.bestEffort("temples page \(page)") {
            try await localDataSource.saveTemplesPage(response)
        }
        return ILCatalogPageEntity(
            items: response.items.map(ILTempleMapper.toDomain),
            page: response.page,
            hasMore: !response.items.isEmpty && response.page < response.totalPages
        )
    }

    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity {
        let response: ILTempleDetailDTO
        do {
            response = try await networkService.request(
                endpoint: TempleDetailEndpoint(id: id),
                responseType: ILTempleDetailDTO.self
            )
        } catch {
            let mapped = ILCatalogError.from(error)
            // The server says the temple is gone — a cached copy would be stale, not a fallback,
            // so drop it (the backend removed temples without photos on 2026-10-06).
            if case .notFound = mapped {
                await ILCatalogCacheWrite.bestEffort("evict temple \(id)") {
                    try await localDataSource.removeTemple(id: id)
                }
                throw mapped
            }
            guard let cached = try? await localDataSource.cachedTempleDetail(id: id) else { throw mapped }
            return cached
        }
        await ILCatalogCacheWrite.bestEffort("temple detail") {
            try await localDataSource.saveTempleDetail(response)
        }
        return ILTempleMapper.toDomain(response)
    }

    private func wrapLocal<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw ILCatalogError.loadFailed(error)
        }
    }
}
