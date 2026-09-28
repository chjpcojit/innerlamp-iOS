//
//  ILDeityRepositoryTests.swift
//  InnerLampTests
//

import CoreData
import XCTest
@testable import InnerLamp

/// Exercises `ILDeityRepositoryImpl` against a real in-memory Core Data stack seeded from the
/// bundled `phat_botat.json` — covering the JSON decoding, the model definition, the seeding, the
/// `ILDeityMO` round-trip and every query.
@MainActor
final class ILDeityRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var repository: ILDeityRepository!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        XCTAssertTrue(stack.isLoaded, "The in-memory store failed to load")
        repository = ILDeityRepositoryImpl(localDataSource: ILDeityLocalDataSourceImpl(stack: stack))
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - Seeding

    func test_loadAll_seedsWholeBundledCatalogInFileOrder() async throws {
        let deities = try await repository.loadAll()

        XCTAssertEqual(deities.count, 18)
        XCTAssertEqual(deities.first?.id, "buddha_shakyamuni")
        XCTAssertEqual(deities.last?.id, "bodhisattva_vajrasattva")
    }

    func test_seeding_isIdempotent() async throws {
        _ = try await repository.loadAll()
        _ = try await repository.loadAll()

        let rowCount = try await stack.performBackgroundTask { context in
            try context.count(for: NSFetchRequest<ILDeityMO>(entityName: ILDeityMO.entityName))
        }
        XCTAssertEqual(rowCount, 18, "Repeated reads must not duplicate seeded rows")
    }

    func test_seeding_matchesDirectJSONDecode() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "phat_botat", withExtension: "json"))
        let decoded = try ILDeityMapper.decodeCatalog(from: Data(contentsOf: url))

        let stored = try await repository.loadAll()
        XCTAssertEqual(stored, decoded, "Core Data round-trip must preserve every field")
    }

    func test_missingSeedFile_surfacesLoadFailed() async {
        let dataSource = ILDeityLocalDataSourceImpl(stack: stack, bundle: Bundle(for: Self.self))
        let repository = ILDeityRepositoryImpl(localDataSource: dataSource)

        do {
            _ = try await repository.loadAll()
            XCTFail("Expected loadFailed")
        } catch let error as ILDeityError {
            guard case .loadFailed = error else { return XCTFail("Unexpected \(error)") }
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: - Mapping

    func test_loadDeity_mapsEveryFieldForKnownDeity() async throws {
        let loaded = try await repository.loadDeity(id: "bodhisattva_avalokiteshvara")
        let deity = try XCTUnwrap(loaded)

        XCTAssertEqual(deity.kind, .bodhisattva)
        XCTAssertEqual(deity.nameVi, "Quán Thế Âm Bồ Tát")
        XCTAssertEqual(deity.nameChinese, "觀世音菩薩")
        XCTAssertEqual(deity.memorialDays.map(\.lunarMonth), [2, 6, 9], "Memorial days keep file order")
        XCTAssertEqual(deity.memorialDays.first?.eventName, "Ngày Đản sinh Quán Thế Âm")
        XCTAssertEqual(deity.iconography.sacredArtifacts.count, 2)
        XCTAssertEqual(deity.greatVows.count, 2)
        XCTAssertEqual(deity.mantra.shortSanskrit, "Oṃ Maṇi Padme Hūṃ")
    }

    func test_loadDeity_unknownID_returnsNil() async throws {
        let deity = try await repository.loadDeity(id: "does_not_exist")
        XCTAssertNil(deity)
    }

    // MARK: - Queries

    func test_loadDeitiesByKind_splitsCatalog() async throws {
        let buddhas = try await repository.loadDeities(kind: .buddha)
        let bodhisattvas = try await repository.loadDeities(kind: .bodhisattva)

        XCTAssertEqual(buddhas.count, 6)
        XCTAssertEqual(bodhisattvas.count, 12)
        XCTAssertTrue(buddhas.allSatisfy { $0.kind == .buddha })
        XCTAssertTrue(bodhisattvas.allSatisfy { $0.kind == .bodhisattva })
    }

    func test_loadDeitiesByLunarDate_matchesDayAndMonthOnSameRow() async throws {
        // 15/4: Shakyamuni (Phật Đản) and Vairocana.
        let phatDan = try await repository.loadDeities(lunarDay: 15, lunarMonth: 4)
        XCTAssertEqual(phatDan.map(\.id), ["buddha_shakyamuni", "buddha_vairocana"])

        // 15/2 belongs to Shakyamuni only; Avalokiteshvara (19/2) and Samantabhadra (21/2) share the
        // month but not the day, and Vajrasattva (15/7) shares the day but not the month.
        let fifteenthOfSecond = try await repository.loadDeities(lunarDay: 15, lunarMonth: 2)
        XCTAssertEqual(fifteenthOfSecond.map(\.id), ["buddha_shakyamuni"])

        let none = try await repository.loadDeities(lunarDay: 2, lunarMonth: 2)
        XCTAssertTrue(none.isEmpty)
    }

    func test_search_isCaseAndDiacriticInsensitiveAcrossNames() async throws {
        let byVietnamese = try await repository.searchDeities(query: "quan the am")
        XCTAssertEqual(byVietnamese.map(\.id), ["bodhisattva_avalokiteshvara"])

        let bySanskrit = try await repository.searchDeities(query: "amitabha")
        XCTAssertEqual(bySanskrit.map(\.id), ["buddha_amitabha"])

        let byChinese = try await repository.searchDeities(query: "地藏")
        XCTAssertEqual(byChinese.map(\.id), ["bodhisattva_ksitigarbha"])
    }

    func test_search_emptyQuery_returnsWholeCatalog() async throws {
        let results = try await repository.searchDeities(query: "   ")
        XCTAssertEqual(results.count, 18)
    }
}
