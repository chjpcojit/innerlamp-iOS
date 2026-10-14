//
//  ILSanghaUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSanghaUseCaseTests: XCTestCase {

    private var storage: InMemoryUserDefaultsService!
    private var accountRepository: StubAccountRepository!
    private var templeRepository: StubTempleDetailRepository!
    private var sut: ILSanghaUseCaseImpl!

    override func setUp() {
        super.setUp()
        storage = InMemoryUserDefaultsService()
        accountRepository = StubAccountRepository()
        templeRepository = StubTempleDetailRepository()
        sut = ILSanghaUseCaseImpl(
            userDefaultsService: storage,
            accountRepository: accountRepository,
            templeRepository: templeRepository,
            now: { Date(timeIntervalSince1970: 1_790_000_000) }
        )
    }

    override func tearDown() {
        sut = nil
        templeRepository = nil
        accountRepository = nil
        storage = nil
        super.tearDown()
    }

    // MARK: - Profile temple

    func test_loadMyTemple_withoutProfileTemple_returnsNil() async {
        accountRepository.result = .success(Self.makeAccount(temple: nil))

        let mine = await sut.loadMyTemple()

        XCTAssertNil(mine)
    }

    func test_loadMyTemple_withProfileTemple_usesItWithCatalogDetail() async {
        accountRepository.result = .success(Self.makeAccount(temple: .init(id: "temple_north_001", name: "Chùa Một Cột")))
        templeRepository.detail = Self.makeDetail(id: "temple_north_001", name: "Chùa Một Cột", address: "Ba Đình, Hà Nội")

        let temple = await sut.loadMyTemple()?.temple

        XCTAssertEqual(temple?.id, "temple_north_001")
        XCTAssertEqual(temple?.name, "Chùa Một Cột")
        XCTAssertEqual(temple?.address, "Ba Đình, Hà Nội")
        XCTAssertEqual(temple?.abbot, "Thượng tọa A")
        XCTAssertEqual(temple?.operatingHours, "06:00 - 18:00")
        XCTAssertEqual(templeRepository.requestedIDs, ["temple_north_001"])
    }

    func test_loadMyTemple_withProfileTemple_whenCatalogFails_keepsTheProfileName() async {
        accountRepository.result = .success(Self.makeAccount(temple: .init(id: "temple_north_001", name: "Chùa Một Cột")))

        let temple = await sut.loadMyTemple()?.temple

        XCTAssertEqual(temple?.id, "temple_north_001")
        XCTAssertEqual(temple?.name, "Chùa Một Cột")
        XCTAssertEqual(temple?.address, "")
    }

    func test_loadMyTemple_whenProfileFails_andNothingChosen_returnsNil() async {
        accountRepository.result = .failure(ILAccountProfileError.offline)

        let mine = await sut.loadMyTemple()

        XCTAssertNil(mine)
    }

    // MARK: - Chosen in the app

    func test_loadMyTemple_withEmptyStoredID_usesTheProfileTemple() async {
        accountRepository.result = .success(Self.makeAccount(temple: .init(id: "temple_north_001", name: "Chùa Một Cột")))
        sut.selectMyTemple(id: "")

        let mine = await sut.loadMyTemple()

        XCTAssertEqual(mine?.temple.id, "temple_north_001")
    }

    func test_selectMyTemple_thenLoadMyTemple_returnsThatTemple_overTheProfileTemple() async {
        accountRepository.result = .success(Self.makeAccount(temple: .init(id: "temple_north_001", name: "Chùa Một Cột")))
        sut.selectMyTemple(id: "temple-xaloi")

        let mine = await sut.loadMyTemple()

        XCTAssertEqual(mine?.temple.id, "temple-xaloi")
    }

    func test_selectMyTemple_fromCatalog_loadsFromSnapshot() async {
        sut.selectMyTemple(ILTempleFinderUseCaseTests.makeTemple(id: "temple_north_001", name: "Chùa Một Cột", address: "Ba Đình, Hà Nội"))

        let temple = await sut.loadMyTemple()?.temple

        XCTAssertEqual(temple?.id, "temple_north_001")
        XCTAssertEqual(temple?.name, "Chùa Một Cột")
        XCTAssertEqual(temple?.address, "Ba Đình, Hà Nội")
        XCTAssertEqual(temple?.operatingHours, "")
    }

    func test_selectMyTemple_fromCatalog_isEnrichedWithCatalogDetail() async {
        sut.selectMyTemple(ILTempleFinderUseCaseTests.makeTemple(id: "temple_north_001", name: "Chùa Một Cột", address: "Hà Nội"))
        templeRepository.detail = Self.makeDetail(id: "temple_north_001", name: "Chùa Một Cột", address: "Ba Đình, Hà Nội")

        let temple = await sut.loadMyTemple()?.temple

        XCTAssertEqual(temple?.imageURL, "https://example.com/full.jpg")
        XCTAssertEqual(temple?.abbot, "Thượng tọa A")
        XCTAssertEqual(temple?.address, "Ba Đình, Hà Nội")
    }

    func test_selectMyTemple_fromCatalog_thenMockTemple_dropsTheCatalogTemple() async {
        sut.selectMyTemple(ILTempleFinderUseCaseTests.makeTemple(id: "temple_north_001", name: "Chùa Một Cột", address: "Hà Nội"))
        sut.selectMyTemple(id: "temple-xaloi")

        let mine = await sut.loadMyTemple()

        XCTAssertEqual(mine?.temple.id, "temple-xaloi")
    }

    func test_loadMyTemple_withUnknownStoredID_fallsBackToTheProfile_thenNil() async {
        sut.selectMyTemple(id: "does-not-exist")
        accountRepository.result = .success(Self.makeAccount(temple: nil))

        let mine = await sut.loadMyTemple()

        XCTAssertNil(mine)
    }

    func test_loadChooser_listsNearbyTemplesSortedByDistance() {
        let distances = sut.loadChooser().nearbyTemples.map(\.distanceKm)
        XCTAssertFalse(distances.isEmpty)
        XCTAssertEqual(distances, distances.sorted())
    }

    func test_loadUpcomingDays_respectsLimit() {
        XCTAssertEqual(sut.loadUpcomingDays(limit: 2).count, 2)
        XCTAssertEqual(sut.loadUpcomingDays(limit: 10).count, 4)
    }
}

private final class InMemoryUserDefaultsService: UserDefaultsService {
    private var store: [String: Data] = [:]

    func save<T: Codable>(key: String, value: T) { store[key] = try? JSONEncoder().encode(value) }
    func load<T: Codable>(key: String, type: T.Type) -> T? {
        store[key].flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    func remove(key: String) { store[key] = nil }
    func exists(key: String) -> Bool { store[key] != nil }
}

extension ILSanghaUseCaseTests {

    fileprivate static func makeAccount(temple: ILAccountProfileEntity.Temple?) -> ILAccountProfileEntity {
        ILAccountProfileEntity(
            email: "a@b.com", isEmailVerified: true, phoneNumber: "+84901234567", fullName: "Nguyễn Bình An",
            dharmaName: "", ordinationTemple: temple, avatarURL: nil, avatarURLExpiresAt: nil
        )
    }

    fileprivate static func makeDetail(id: String, name: String, address: String) -> ILTempleDetailEntity {
        ILTempleDetailEntity(
            summary: ILTempleFinderUseCaseTests.makeTemple(
                id: id, name: name, address: address, imageURL: "https://example.com/full.jpg"
            ),
            aliases: [], founder: "", currentAbbot: "Thượng tọa A", operatingHours: "06:00 - 18:00",
            facilities: ILTempleFacilitiesEntity(
                hasCarParking: false, hasMotorbikeParking: false, servesVegetarianMeals: false, hasSummerRetreat: false
            ),
            introduction: "", architectureHeritage: "", visitingNotes: []
        )
    }
}

private final class StubAccountRepository: ILAccountProfileRepository {
    var result: Result<ILAccountProfileEntity, Error> = .failure(ILAccountProfileError.loadFailed)

    func loadAccountProfile() async throws -> ILAccountProfileEntity { try result.get() }
}

private final class StubTempleDetailRepository: ILTempleRepository {
    var detail: ILTempleDetailEntity?
    private(set) var requestedIDs: [String] = []

    func loadTopTemples() async throws -> [ILTempleSummaryEntity] { [] }

    func loadTemples(page: Int) async throws -> ILCatalogPageEntity<ILTempleSummaryEntity> {
        ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadTempleDetail(id: String) async throws -> ILTempleDetailEntity {
        requestedIDs.append(id)
        guard let detail else { throw ILCatalogError.notFound }
        return detail
    }
}
