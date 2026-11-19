//
//  ILMemorialRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server memorial book + Core Data cache. The server is the source of truth: reads go to the
/// network and refresh the cache; the cache is returned only when the device is offline. Writes
/// need the network and update the cache after the server accepts them (D5).
nonisolated final class ILMemorialRepositoryImpl: ILMemorialRepository {

    /// Contract §3.6: `5 × 1024 × 1024`. Checked here as well as in the form so an oversized
    /// image never leaves the device.
    static let maxPhotoBytes = 5 * 1024 * 1024

    private let networkService: NetworkService
    private let multipartUploader: MultipartUploading
    private let localDataSource: ILMemorialLocalDataSource

    init(
        networkService: NetworkService,
        multipartUploader: MultipartUploading,
        localDataSource: ILMemorialLocalDataSource
    ) {
        self.networkService = networkService
        self.multipartUploader = multipartUploader
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
                  case let servedFromCache = cached.filter({ Int64($0.id) != nil }),
                  !servedFromCache.isEmpty else { throw mapped }
            return servedFromCache
        }

        let entries: [ILMemorialEntity]
        do {
            entries = try response.items.map(ILMemorialMapper.toDomain)
        } catch {
            // A value this client cannot represent (unknown enum) fails the load instead of
            // showing a guessed row (contract §2.2).
            throw ILMemorialError.loadFailed(error)
        }
        await ILCatalogCacheWrite.bestEffort("memorial list") {
            try await localDataSource.replaceAll(entries)
        }
        return entries
    }

    func save(_ entry: ILMemorialEntity) async throws -> ILMemorialEntity {
        let request: ILMemorialRequestDTO
        do {
            request = try ILMemorialMapper.toRequest(entry)
        } catch {
            throw ILMemorialError.invalidInput
        }

        let dto: ILMemorialDTO
        do {
            // A server id is numeric; a new entry carries a local UUID until the server assigns one.
            let endpoint: Endpoint = Int64(entry.id) != nil
                ? MemorialUpdateEndpoint(id: entry.id, request: request)
                : MemorialCreateEndpoint(request: request)
            dto = try await networkService.request(endpoint: endpoint, responseType: ILMemorialDTO.self)
        } catch {
            throw ILMemorialError.from(error, fallback: ILMemorialError.saveFailed)
        }
        return try await cache(dto, context: "memorial save")
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

    func uploadPhoto(entryID: String, jpegData: Data) async throws -> ILMemorialEntity {
        guard jpegData.count <= Self.maxPhotoBytes else { throw ILMemorialError.photoTooLarge }

        let form = MultipartFormData.singleFile(
            field: "photo",
            filename: "memorial-\(entryID).jpg",
            mimeType: "image/jpeg",
            fileData: jpegData
        )
        let dto: ILMemorialDTO
        do {
            dto = try await multipartUploader.upload(
                endpoint: MemorialPhotoUploadEndpoint(id: entryID),
                form: form,
                responseType: ILMemorialDTO.self
            )
        } catch {
            throw ILMemorialError.fromPhoto(error)
        }
        return try await cache(dto, context: "memorial photo upload")
    }

    func deletePhoto(entryID: String) async throws -> ILMemorialEntity {
        let dto: ILMemorialDTO
        do {
            dto = try await networkService.request(
                endpoint: MemorialPhotoDeleteEndpoint(id: entryID),
                responseType: ILMemorialDTO.self
            )
        } catch {
            throw ILMemorialError.fromPhoto(error)
        }
        return try await cache(dto, context: "memorial photo delete")
    }

    // MARK: - Helpers

    private func cache(_ dto: ILMemorialDTO, context: String) async throws -> ILMemorialEntity {
        let saved: ILMemorialEntity
        do {
            saved = try ILMemorialMapper.toDomain(dto)
        } catch {
            throw ILMemorialError.saveFailed(error)
        }
        await ILCatalogCacheWrite.bestEffort(context) {
            try await localDataSource.upsert(saved)
        }
        return saved
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
            case "PHOTO_TOO_LARGE": return .photoTooLarge
            case "PHOTO_UNSUPPORTED_TYPE": return .photoUnsupported
            default: return fallback(networkError)
            }
        default:
            return fallback(networkError)
        }
    }

    /// Photo errors need their own fallback so a 5xx on an upload reads as "save failed" rather
    /// than as a generic load failure.
    static func fromPhoto(_ error: Error) -> ILMemorialError {
        if case let NetworkError.serverError(statusCode, _) = error {
            // Some proxies strip the envelope; on the photo route the status alone identifies these.
            switch statusCode {
            case 413: return .photoTooLarge
            case 415: return .photoUnsupported
            default: break
            }
        }
        return from(error, fallback: ILMemorialError.saveFailed)
    }
}
