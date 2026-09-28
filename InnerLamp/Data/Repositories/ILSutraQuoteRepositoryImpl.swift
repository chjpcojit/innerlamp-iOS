//
//  ILSutraQuoteRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Repository over the local sutra quote store.
///
/// `ILSutraQuoteLocalDataSource` does the Core Data and JSON work; this type translates its
/// failures into the `ILSutraQuoteError` cases the Domain contract promises.
nonisolated final class ILSutraQuoteRepositoryImpl: ILSutraQuoteRepository {

    private let localDataSource: ILSutraQuoteLocalDataSource

    init(localDataSource: ILSutraQuoteLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func seedIfNeeded() async throws {
        do {
            try await localDataSource.seedIfNeeded()
        } catch {
            throw ILSutraQuoteError.seedFailed(error)
        }
    }

    func count() async throws -> Int {
        try await load { try await localDataSource.count() }
    }

    func quote(at index: Int) async throws -> ILSutraQuoteEntity? {
        try await load { try await localDataSource.fetchQuote(at: index) }
    }

    func loadAll() async throws -> [ILSutraQuoteEntity] {
        try await load { try await localDataSource.fetchAll() }
    }

    private func load<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw ILSutraQuoteError.loadFailed(error)
        }
    }
}
