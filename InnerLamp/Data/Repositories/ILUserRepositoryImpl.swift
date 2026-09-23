//
//  ILUserRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Repository over the local user store.
///
/// Owns no storage mechanism of its own — `ILUserLocalDataSource` performs the Core Data work and
/// this type's remaining job is to translate its failures into the `ILUserError` cases the Domain
/// contract promises. That translation is the point of the split: `ILUserError` is Domain vocabulary
/// and only this layer may decide which storage failure maps to which case.
///
/// When a remote source lands, this becomes the place that chooses between them (cache hit → local,
/// miss → remote → write through); the local path already sits behind its own type. Until then it is
/// a pass-through, and `ILUserMO` never appears here.
///
/// `nonisolated` so the whole type is callable from the background context the stack hands out —
/// see `CoreDataStack` for why default MainActor isolation has to be opted out of here.
nonisolated final class ILUserRepositoryImpl: ILUserRepository {

    private let localDataSource: ILUserLocalDataSource

    init(localDataSource: ILUserLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func loadUser() async throws -> ILUserEntity? {
        do {
            return try await localDataSource.fetchUser()
        } catch {
            throw ILUserError.loadFailed(error)
        }
    }

    func saveUser(_ entity: ILUserEntity) async throws {
        do {
            try await localDataSource.saveUser(entity)
        } catch {
            throw ILUserError.saveFailed(error)
        }
    }

    func deleteUser() async throws {
        do {
            try await localDataSource.deleteUser()
        } catch {
            throw ILUserError.deleteFailed(error)
        }
    }
}
