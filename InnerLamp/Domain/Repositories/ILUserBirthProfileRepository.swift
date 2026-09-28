//
//  ILUserBirthProfileRepository.swift
//  InnerLamp
//

import Foundation

/// Reads and writes the locally stored user birth profile (for personalized Trạch Cát).
///
/// Singleton-shaped like `ILUserRepository`: the app holds at most one birth profile. Entity in,
/// entity out — no DTO, no `CoreData` import. The profile is written once when the user enters their
/// birthday and read on every almanac query (`ILAlmanacUseCase.calculateDailyAlmanac`).
nonisolated protocol ILUserBirthProfileRepository {

    /// The stored birth profile, or `nil` when none has been saved yet.
    func loadBirthProfile() async throws -> ILUserBirthProfileEntity?

    /// Stores `profile` as *the* birth profile, replacing any previously stored one (upsert).
    func saveBirthProfile(_ profile: ILUserBirthProfileEntity) async throws

    /// Removes the stored birth profile. No-op when there is none.
    func deleteBirthProfile() async throws
}

/// Failures surfaced by `ILUserBirthProfileRepository`. Mirrors `ILUserError`.
enum ILUserBirthProfileError: Error, LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "userBirthProfile.error.loadFailed".localized
        case .saveFailed:
            return "userBirthProfile.error.saveFailed".localized
        case .deleteFailed:
            return "userBirthProfile.error.deleteFailed".localized
        }
    }
}
