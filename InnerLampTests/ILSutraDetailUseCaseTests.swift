//
//  ILSutraDetailUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSutraDetailUseCaseTests: XCTestCase {

    func test_loadSutra_wrapsRepositoryResult() async throws {
        let repository = MockILSutraRepository()
        let sut = ILSutraDetailUseCaseImpl(sutraRepository: repository)

        let entity = try await sut.loadSutra(id: "kinh-tu-bi")

        XCTAssertEqual(repository.detailCalls, ["kinh-tu-bi"])
        XCTAssertEqual(entity.sutra, repository.detail)
    }

    func test_loadSutra_propagatesRepositoryError() async {
        let repository = MockILSutraRepository()
        repository.detailError = ILCatalogError.notFound
        let sut = ILSutraDetailUseCaseImpl(sutraRepository: repository)

        do {
            _ = try await sut.loadSutra(id: "zzz")
            XCTFail("Expected notFound")
        } catch {
            guard case ILCatalogError.notFound = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }
}
