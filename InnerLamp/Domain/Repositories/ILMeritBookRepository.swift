//
//  ILMeritBookRepository.swift
//  InnerLamp
//

import Foundation

protocol ILMeritBookRepository {
    /// The signed-in user's merit book: offering history, temple letter, monthly support and the
    /// temple's public financial disclosure.
    func fetchMeritBook() async throws -> ILMeritBookEntity

    /// Stops the recurring monthly offering. A no-op when none is active.
    func stopMonthlySupport() async throws
}
