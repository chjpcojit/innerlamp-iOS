//
//  ILSutraQuoteUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSutraQuoteUseCase {

    /// Seeds the bundled catalog into the store if it is not there yet. Called once at launch so
    /// the first screen that needs a quote does not pay for the import.
    func prepare() async throws

    /// The fixed quote for the calendar day containing `date`.
    ///
    /// Index = day-of-year (1...366) modulo the catalog size, so every day of the year maps to the
    /// same quote no matter how many times it is viewed. Returns `nil` when the catalog is empty.
    func quote(for date: Date) async throws -> ILSutraQuoteEntity?

    /// A uniformly random quote, or `nil` when the catalog is empty.
    func randomQuote() async throws -> ILSutraQuoteEntity?

    /// Up to `count` distinct random quotes (fewer when the catalog is smaller).
    func randomQuotes(count: Int) async throws -> [ILSutraQuoteEntity]
}

final class ILSutraQuoteUseCaseImpl: ILSutraQuoteUseCase {

    private let repository: ILSutraQuoteRepository
    private let calendar: Calendar

    init(repository: ILSutraQuoteRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func prepare() async throws {
        try await repository.seedIfNeeded()
    }

    func quote(for date: Date) async throws -> ILSutraQuoteEntity? {
        let total = try await repository.count()
        guard let index = Self.quoteIndex(for: date, totalCount: total, calendar: calendar) else { return nil }
        return try await repository.quote(at: index)
    }

    func randomQuote() async throws -> ILSutraQuoteEntity? {
        let total = try await repository.count()
        guard total > 0 else { return nil }
        return try await repository.quote(at: Int.random(in: 0..<total))
    }

    func randomQuotes(count: Int) async throws -> [ILSutraQuoteEntity] {
        guard count > 0 else { return [] }
        let all = try await repository.loadAll()
        return Array(all.shuffled().prefix(count))
    }

    /// Pure day-of-year rotation: `dayOfYear % totalCount`, `dayOfYear` being 1-based.
    /// `nil` when `totalCount` is not positive.
    static func quoteIndex(for date: Date, totalCount: Int, calendar: Calendar) -> Int? {
        guard totalCount > 0,
              let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) else { return nil }
        return dayOfYear % totalCount
    }
}
