//
//  ILMemorialRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server memorial book + Core Data cache. The server is the source of truth: reads go to the
/// network and refresh the cache; the cache is returned only when the device is offline. Writes
/// need the network and update the cache after the server accepts them.
nonisolated final class ILMemorialRepositoryImpl: ILMemorialRepository {

    private let networkService: NetworkService
    private let localDataSource: ILMemorialLocalDataSource

    init(networkService: NetworkService, localDataSource: ILMemorialLocalDataSource) {
        self.networkService = networkService
        self.localDataSource = localDataSource
    }

    func loadAll() async throws -> [ILMemorialEntity] {
        let response: ILMemorialListDTO
        do {
            response = try await networkService.request(
                endpoint: MemorialsListEndpoint(),
                responseType: ILMemorialListDTO.self
            )
        } catch {
            let mapped = ILMemorialError.from(error, fallback: ILMemorialError.loadFailed)
            // Offline only: any other failure (e.g. 401) must not show another session's cache.
            // Entries without a numeric id predate the server API and cannot be edited — skip them.
            guard case .offline = mapped,
                  let cached = try? await localDataSource.fetchAll(),
                  case let servedFromCache = cached.filter({ Int($0.id) != nil }),
                  !servedFromCache.isEmpty else { throw mapped }
            return servedFromCache
        }
        let entries = response.items.map(ILMemorialMapper.toDomain)
        await ILCatalogCacheWrite.bestEffort("memorial list") {
            try await localDataSource.replaceAll(entries)
        }
        return entries
    }

    func save(_ entry: ILMemorialEntity) async throws {
        let request: ILMemorialRequestDTO
        do {
            request = try ILMemorialMapper.toRequest(entry)
        } catch {
            throw ILMemorialError.invalidInput
        }

        let dto: ILMemorialDTO
        do {
            // A server id is numeric; a new entry carries a local UUID until the server assigns one.
            let endpoint: Endpoint = Int(entry.id) != nil
                ? MemorialUpdateEndpoint(id: entry.id, request: request)
                : MemorialCreateEndpoint(request: request)
            dto = try await networkService.request(endpoint: endpoint, responseType: ILMemorialDTO.self)
        } catch {
            throw ILMemorialError.from(error, fallback: ILMemorialError.saveFailed)
        }
        let saved = ILMemorialMapper.toDomain(dto)
        await ILCatalogCacheWrite.bestEffort("memorial save") {
            try await localDataSource.upsert(saved)
        }
    }

    func delete(id: String) async throws {
        do {
            try await networkService.request(endpoint: MemorialDeleteEndpoint(id: id))
        } catch {
            let mapped = ILMemorialError.from(error, fallback: ILMemorialError.deleteFailed)
            // Already gone on the server — the goal of the delete is met.
            guard case .notFound = mapped else { throw mapped }
        }
        await ILCatalogCacheWrite.bestEffort("memorial delete") {
            try await localDataSource.delete(id: id)
        }
    }
}

nonisolated extension ILMemorialError {

    /// Maps a transport failure to the Domain error. Branches on the server's `error.code`, never
    /// on its message; anything unrecognised becomes `fallback(error)`.
    static func from(_ error: Error, fallback: (Error) -> ILMemorialError) -> ILMemorialError {
        if let memorialError = error as? ILMemorialError { return memorialError }
        guard let networkError = error as? NetworkError else { return fallback(error) }
        switch networkError {
        case .noInternetConnection, .timeout:
            return .offline
        case .unauthorized:
            return .unauthorized
        case .apiError(let code, _, _, _):
            switch code {
            case "MEMORIAL_LIMIT_REACHED": return .limitReached
            case "MEMORIAL_NOT_FOUND": return .notFound
            case "VALIDATION_ERROR": return .invalidInput
            case "UNAUTHORIZED": return .unauthorized
            default: return fallback(networkError)
            }
        default:
            return fallback(networkError)
        }
    }
}
