//
//  ILSutraQuoteRepositoryTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// Exercises `ILSutraQuoteRepositoryImpl` against a real in-memory Core Data stack, covering the
/// model definition, the bundled JSON import and the `ILSutraQuoteMO` mapping.
final class ILSutraQuoteRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load")
    }

    override func tearDown() {
        stack = nil
        super.tearDown()
    }

    private func makeRepository(seed: (() throws -> [ILSutraQuoteDTO])? = nil) -> ILSutraQuoteRepository {
        ILSutraQuoteRepositoryImpl(localDataSource: ILSutraQuoteLocalDataSourceImpl(stack: stack, loadSeed: seed))
    }

    private func dto(_ stt: Int, content: String = "Nội dung") -> ILSutraQuoteDTO {
        ILSutraQuoteDTO(stt: stt, kinh: "Kinh", dichGia: "Dịch giả", phamSo: "I",
                        phamTen: "Phẩm", keSo: stt * 10, noiDung: content)
    }

    private func storedRowCount() async throws -> Int {
        try await stack.performBackgroundTask { context in
            try context.count(for: NSFetchRequest<ILSutraQuoteMO>(entityName: ILSutraQuoteMO.entityName))
        }
    }

    // MARK: - Bundled catalog

    func test_seedIfNeeded_importsAllBundledQuotes() async throws {
        let repository = makeRepository()

        try await repository.seedIfNeeded()

        let count = try await repository.count()
        XCTAssertEqual(count, 300)
    }

    func test_bundledCatalog_mapsFirstQuoteFields() async throws {
        let repository = makeRepository()

        let first = try await XCTUnwrapAsync(await repository.quote(at: 0))

        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(first.sutraName, "Kinh Pháp Cú (Dhammapada)")
        XCTAssertEqual(first.translator, "Hòa thượng Thích Minh Châu")
        XCTAssertEqual(first.chapterNumber, "I")
        XCTAssertEqual(first.chapterName, "Phẩm Song Yếu")
        XCTAssertEqual(first.verseNumber, 5)
        XCTAssertTrue(first.content.hasPrefix("Với hận diệt hận thù"))
    }

    // MARK: - Seeding behaviour

    func test_seedIfNeeded_isIdempotent() async throws {
        let repository = makeRepository(seed: { [unowned self] in [dto(1), dto(2), dto(3)] })

        try await repository.seedIfNeeded()
        try await repository.seedIfNeeded()
        try await repository.seedIfNeeded()

        let rows = try await storedRowCount()
        XCTAssertEqual(rows, 3)
    }

    func test_seedIfNeeded_insertsOnlyNewRecordsAndKeepsExisting() async throws {
        try await makeRepository(seed: { [unowned self] in [dto(1, content: "cũ")] }).seedIfNeeded()

        let updated = makeRepository(seed: { [unowned self] in [dto(1, content: "mới"), dto(2)] })
        try await updated.seedIfNeeded()

        let all = try await updated.loadAll()
        XCTAssertEqual(all.map(\.id), [1, 2])
        XCTAssertEqual(all.first?.content, "cũ", "Existing rows must not be overwritten")
    }

    func test_reads_seedOnDemandWhenStoreIsEmpty() async throws {
        let repository = makeRepository(seed: { [unowned self] in [dto(1), dto(2)] })

        let count = try await repository.count()

        XCTAssertEqual(count, 2)
    }

    func test_seedIfNeeded_wrapsLoaderFailureAsSeedFailed() async {
        struct Boom: Error {}
        let repository = makeRepository(seed: { throw Boom() })

        do {
            try await repository.seedIfNeeded()
            XCTFail("Expected seedFailed")
        } catch ILSutraQuoteError.seedFailed {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: - Queries

    func test_quoteAt_followsSequenceOrderAndHandlesOutOfRange() async throws {
        let repository = makeRepository(seed: { [unowned self] in [dto(3), dto(1), dto(2)] })

        let first = try await repository.quote(at: 0)
        let last = try await repository.quote(at: 2)
        let beyond = try await repository.quote(at: 3)
        let negative = try await repository.quote(at: -1)

        XCTAssertEqual(first?.id, 1)
        XCTAssertEqual(last?.id, 3)
        XCTAssertNil(beyond)
        XCTAssertNil(negative)
    }
}

/// `XCTUnwrap` for an optional produced by an `await` expression.
private func XCTUnwrapAsync<T>(
    _ expression: @autoclosure () async throws -> T?,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    let value = try await expression()
    return try XCTUnwrap(value, file: file, line: line)
}
