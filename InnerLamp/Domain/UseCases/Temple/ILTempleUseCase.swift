//
//  ILTempleUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILTempleUseCase {
    /// Full profile of the temple with `id` from `GET /v1/temples/{id}` (network-first, cached copy
    /// when offline). Throws `ILCatalogError` — `.notFound` for an unknown id, `.offline` when the
    /// server is unreachable and nothing is cached.
    func loadTemple(id: String) async throws -> ILTempleDetailEntity

    /// Follow / unfollow a temple — needs a followed-temples repository (not built yet).
    func toggleFollow(templeID: String) async throws
}

final class ILTempleUseCaseImpl: ILTempleUseCase {

    private let templeRepository: ILTempleRepository

    init(templeRepository: ILTempleRepository) {
        self.templeRepository = templeRepository
    }

    func loadTemple(id: String) async throws -> ILTempleDetailEntity {
        try await templeRepository.loadTempleDetail(id: id)
    }

    func toggleFollow(templeID: String) async throws {
        print("TODO: implement toggleFollow — repository call, not built by il-screen-builder")
    }
}
