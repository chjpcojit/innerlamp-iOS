//
//  ILDeityRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Repository over the local "Buddhas & Bodhisattvas" catalog store.
///
/// `ILDeityLocalDataSource` performs the Core Data work (including seeding); this type's job is to
/// translate its failures into the `ILDeityError` cases the Domain contract promises. When a remote
/// catalog lands, this becomes the place that chooses between sources.
///
/// `nonisolated` so the whole type is callable from the background context the stack hands out.
nonisolated final class ILDeityRepositoryImpl: ILDeityRepository {

    private let localDataSource: ILDeityLocalDataSource

    init(localDataSource: ILDeityLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func loadAll() async throws -> [ILDeityEntity] {
        try await wrap { try await localDataSource.fetchAll() }
    }

    func loadDeity(id: String) async throws -> ILDeityEntity? {
        try await wrap { try await localDataSource.fetchDeity(id: id) }
    }

    func loadDeities(kind: ILDeityKind) async throws -> [ILDeityEntity] {
        try await wrap { try await localDataSource.fetchDeities(kind: kind) }
    }

    func loadDeities(lunarDay: Int, lunarMonth: Int) async throws -> [ILDeityEntity] {
        try await wrap { try await localDataSource.fetchDeities(lunarDay: lunarDay, lunarMonth: lunarMonth) }
    }

    func searchDeities(query: String) async throws -> [ILDeityEntity] {
        try await wrap { try await localDataSource.searchDeities(query: query) }
    }

    private func wrap<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw ILDeityError.loadFailed(error)
        }
    }
}
