//
//  ILAccountProfileRepositoryImpl.swift
//  InnerLamp
//

import Foundation

nonisolated final class ILAccountProfileRepositoryImpl: ILAccountProfileRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadAccountProfile() async throws -> ILAccountProfileEntity {
        do {
            let dto = try await networkService.request(
                endpoint: UserMeEndpoint(),
                responseType: ILUserMeDTO.self
            )
            return ILAccountProfileMapper.toDomain(dto)
        } catch {
            throw ILAccountProfileError.from(error)
        }
    }
}

nonisolated extension ILAccountProfileError {

    /// Branches on the server's `error.code`, never on its message.
    static func from(_ error: Error) -> ILAccountProfileError {
        if let known = error as? ILAccountProfileError { return known }
        guard let networkError = error as? NetworkError else { return .loadFailed }
        switch networkError {
        case .noInternetConnection, .timeout:
            return .offline
        case .unauthorized:
            return .unauthorized
        case .apiError(let code, _, _, _):
            switch code {
            case "UNAUTHORIZED": return .unauthorized
            case "RATE_LIMITED": return .rateLimited
            default: return .loadFailed
            }
        default:
            return .loadFailed
        }
    }
}
