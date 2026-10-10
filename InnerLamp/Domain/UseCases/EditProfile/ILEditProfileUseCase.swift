//
//  ILEditProfileUseCase.swift
//  InnerLamp
//

import Foundation

/// Client-side validation failures of the Edit Profile form.
enum ILEditProfileValidationError: Error, Equatable {
    /// Display name is empty (or whitespace only).
    case displayNameRequired
}

protocol ILEditProfileUseCase {
    /// Returns the profile being edited. Currently mock data because no profile API/storage
    /// contract is confirmed — replace with an `ILEditProfileRepository` via data-builder.
    func getProfile() -> ILEditProfileEntity

    /// Pure client-side validation of the display name. Returns `nil` when valid.
    func validateDisplayName(_ name: String) -> ILEditProfileValidationError?

    /// Persists the edited profile (network call — not built yet).
    func saveProfile(_ profile: ILEditProfileEntity) async throws
}

final class ILEditProfileUseCaseImpl: ILEditProfileUseCase {

    init() {}

    func getProfile() -> ILEditProfileEntity {
        // TODO: no confirmed profile API — replace this mock (matches the prototype `edit` screen)
        // with ILEditProfileRepository once the contract exists (use data-builder).
        ILEditProfileEntity(
            displayName: "editProfile.mock.displayName".localized,
            phoneNumber: "editProfile.mock.phone".localized,
            templeName: "editProfile.mock.temple".localized,
            bio: "editProfile.mock.bio".localized,
            streakVisibility: .publicToSangha,
            journalVisibility: .onlyMe,
            offeringHistoryVisibility: .anonymous
        )
    }

    func validateDisplayName(_ name: String) -> ILEditProfileValidationError? {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .displayNameRequired : nil
    }

    func saveProfile(_ profile: ILEditProfileEntity) async throws {
        print("TODO: implement saveProfile — network/repository call, not built by ui-builder")
    }
}
