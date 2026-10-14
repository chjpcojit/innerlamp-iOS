//
//  ILLampRepository.swift
//  InnerLamp
//

import Foundation

/// Storage of the lamps the user has lit. Local only for now (Core Data); a remote source can be
/// added behind the same protocol once a lamp API exists.
nonisolated protocol ILLampRepository {

    /// Every stored lamp, including ones that have gone out, in no particular order.
    func loadAll() async throws -> [ILLampEntity]

    /// Stores a newly lit lamp (or replaces the one with the same id).
    func save(_ lamp: ILLampEntity) async throws
}

/// Failure of the lamp storage. `errorDescription` is shown to the user as-is; the underlying
/// error stays attached for logging.
enum ILLampError: Error, LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed: return "lightLamp.error.loadFailed".localized
        case .saveFailed: return "lightLamp.error.saveFailed".localized
        }
    }
}
