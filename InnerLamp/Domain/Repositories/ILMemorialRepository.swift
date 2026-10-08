//
//  ILMemorialRepository.swift
//  InnerLamp
//

import Foundation

/// Storage of the memorial book. The server (`/v1/memorials`) is the source of truth; Core Data is
/// a read cache used only when the device is offline. Writes need the network.
nonisolated protocol ILMemorialRepository {

    /// Every saved entry, in no particular order. Falls back to the cache only when offline.
    func loadAll() async throws -> [ILMemorialEntity]

    /// Creates the entry on the server, or replaces it when `id` is a server id (numeric).
    func save(_ entry: ILMemorialEntity) async throws

    /// Removes the entry with `id`; a missing id is not an error.
    func delete(id: String) async throws
}

/// Failure of the memorial book storage. `errorDescription` is shown to the user as-is; the
/// underlying error stays attached for logging.
enum ILMemorialError: Error, LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case offline
    case unauthorized
    /// The server holds 100 entries already (`MEMORIAL_LIMIT_REACHED`).
    case limitReached
    /// The server rejected a field, or the date does not exist (`VALIDATION_ERROR`).
    case invalidInput
    /// The server has no entry with that id (`MEMORIAL_NOT_FOUND`).
    case notFound

    var errorDescription: String? {
        switch self {
        case .loadFailed: return "memorial.error.loadFailed".localized
        case .saveFailed: return "memorial.error.saveFailed".localized
        case .deleteFailed: return "memorial.error.deleteFailed".localized
        case .offline: return "memorial.error.offline".localized
        case .unauthorized: return "memorial.error.unauthorized".localized
        case .limitReached: return "memorial.error.limitReached".localized
        case .invalidInput: return "memorial.error.invalidInput".localized
        case .notFound: return "memorial.error.notFound".localized
        }
    }
}
