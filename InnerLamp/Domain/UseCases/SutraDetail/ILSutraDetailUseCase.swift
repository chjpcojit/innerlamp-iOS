//
//  ILSutraDetailUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

protocol ILSutraDetailUseCase {
    /// `GET /v1/sutras/{id}`. Throws `ILCatalogError` (`.notFound` for an unknown id, `.offline`
    /// when the server is unreachable).
    func loadSutra(id: String) async throws -> ILSutraDetailEntity
}

final class ILSutraDetailUseCaseImpl: ILSutraDetailUseCase {

    private let sutraRepository: ILSutraRepository

    init(sutraRepository: ILSutraRepository) {
        self.sutraRepository = sutraRepository
    }

    func loadSutra(id: String) async throws -> ILSutraDetailEntity {
        ILSutraDetailEntity(sutra: try await sutraRepository.loadSutra(id: id))
    }
}
