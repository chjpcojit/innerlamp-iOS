//
//  ILUserRepository.swift
//  InnerLamp
//

import Foundation

/// Reads and writes the locally stored user profile.
///
/// Singleton-shaped rather than `loadUser(id:)`: the app holds at most one signed-in user at a time
/// — `ILAuthSessionEntity` carries exactly one `user` — so an id parameter would force every caller
/// to remember an id that nothing hands out. If multi-account ever lands, add `loadUser(id:)`
/// alongside these; that is the point at which the use case exists.
///
/// Entity in, entity out. No DTO, no `CoreData` import — the storage shape is a Data-layer concern.
nonisolated protocol ILUserRepository {

    /// The stored user, or `nil` when nothing has been saved yet.
    func loadUser() async throws -> ILUserEntity?

    /// Stores `entity` as *the* user, replacing any previously stored one.
    ///
    /// Upsert semantics: saving twice leaves one record, not two.
    func saveUser(_ entity: ILUserEntity) async throws

    /// Removes the stored user. No-op when there is none.
    func deleteUser() async throws
}

/// Failures surfaced by `ILUserRepository`.
///
/// Each case carries the underlying error. `errorDescription` deliberately ignores it — the message
/// a user sees should not change with the storage layer's mood — but dropping it entirely would
/// make the first real failure impossible to diagnose. Log it, do not render it.
enum ILUserError: Error, LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "user.error.loadFailed".localized
        case .saveFailed:
            return "user.error.saveFailed".localized
        case .deleteFailed:
            return "user.error.deleteFailed".localized
        }
    }
}
