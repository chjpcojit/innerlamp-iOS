//
//  ILLampRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Local-only lamp storage: wraps the Core Data data source and maps failures to `ILLampError`.
// @ai: assumption — see Docs/Assumptions/LightLamp/AS-LightLamp-001-local-only-no-api.md
nonisolated final class ILLampRepositoryImpl: ILLampRepository {

    private let localDataSource: ILLampLocalDataSource

    init(localDataSource: ILLampLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func loadAll() async throws -> [ILLampEntity] {
        do {
            return try await localDataSource.fetchAll()
        } catch {
            throw ILLampError.loadFailed(error)
        }
    }

    func save(_ lamp: ILLampEntity) async throws {
        do {
            try await localDataSource.upsert(lamp)
        } catch {
            throw ILLampError.saveFailed(error)
        }
    }
}
