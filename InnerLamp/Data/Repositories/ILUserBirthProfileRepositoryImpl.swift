//
//  ILUserBirthProfileRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Repository over the local user birth profile store.
///
/// Owns no storage mechanism of its own — `ILUserBirthProfileLocalDataSource` performs the Core Data
/// work and this type's remaining job is to translate its failures into the
/// `ILUserBirthProfileError` cases the Domain contract promises. `ILUserBirthProfileMO` never appears
/// here.
///
/// `nonisolated` so the whole type is callable from the background context the stack hands out.
nonisolated final class ILUserBirthProfileRepositoryImpl: ILUserBirthProfileRepository {

    private let localDataSource: ILUserBirthProfileLocalDataSource

    init(localDataSource: ILUserBirthProfileLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func loadBirthProfile() async throws -> ILUserBirthProfileEntity? {
        do {
            return try await localDataSource.fetchBirthProfile()
        } catch {
            throw ILUserBirthProfileError.loadFailed(error)
        }
    }

    func saveBirthProfile(_ profile: ILUserBirthProfileEntity) async throws {
        do {
            try await localDataSource.saveBirthProfile(profile)
        } catch {
            throw ILUserBirthProfileError.saveFailed(error)
        }
    }

    func deleteBirthProfile() async throws {
        do {
            try await localDataSource.deleteBirthProfile()
        } catch {
            throw ILUserBirthProfileError.deleteFailed(error)
        }
    }
}
