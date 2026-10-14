//
//  ILMeritBookUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMeritBookUseCase {
    func getMeritBook() async throws -> ILMeritBookEntity
    func stopMonthlySupport() async throws
}

final class ILMeritBookUseCaseImpl: ILMeritBookUseCase {

    private let repository: ILMeritBookRepository

    init(repository: ILMeritBookRepository) {
        self.repository = repository
    }

    func getMeritBook() async throws -> ILMeritBookEntity {
        try await repository.fetchMeritBook()
    }

    func stopMonthlySupport() async throws {
        try await repository.stopMonthlySupport()
    }
}
