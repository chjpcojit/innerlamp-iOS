//
//  ILLogoutRepositoryImpl.swift
//  InnerLamp
//

import Foundation

nonisolated final class ILLogoutRepositoryImpl: ILLogoutRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func revokeSession() async throws {
        try await networkService.request(endpoint: LogoutEndpoint())
    }
}
