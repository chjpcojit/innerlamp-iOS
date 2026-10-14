//
//  ILMeritBookUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILMeritBookUseCaseTests: XCTestCase {

    func test_getMeritBook_returnsRepositoryEntity() async throws {
        let repository = ILMeritBookRepositoryImpl()
        let sut = ILMeritBookUseCaseImpl(repository: repository)

        let book = try await sut.getMeritBook()

        XCTAssertEqual(book.offerings.count, 5)
        XCTAssertNotNil(book.monthlySupport)
        XCTAssertNotNil(book.letter)
        XCTAssertNotNil(book.buildProject)
    }

    func test_stopMonthlySupport_clearsMonthlySupportOnNextFetch() async throws {
        let repository = ILMeritBookRepositoryImpl()
        let sut = ILMeritBookUseCaseImpl(repository: repository)

        try await sut.stopMonthlySupport()
        let book = try await sut.getMeritBook()

        XCTAssertNil(book.monthlySupport)
    }
}
