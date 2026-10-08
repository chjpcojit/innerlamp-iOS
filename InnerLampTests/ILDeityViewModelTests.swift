//
//  ILDeityViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILDeityViewModelTests: XCTestCase {

    private var mockUseCase: MockILDeityUseCase!
    private var sut: ILDeityViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var retryTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var biographyToggledSubject: PassthroughSubject<Void, Never>!
    private var vowsToggledSubject: PassthroughSubject<Void, Never>!
    private var festivalsTappedSubject: PassthroughSubject<Void, Never>!
    private var chantTappedSubject: PassthroughSubject<Int, Never>!
    private var shareTappedSubject: PassthroughSubject<Int, Never>!
    private var sutraTappedSubject: PassthroughSubject<Int, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILDeityUseCase()
        cancellables = []
        viewDidLoadSubject = PassthroughSubject()
        retryTappedSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        biographyToggledSubject = PassthroughSubject()
        vowsToggledSubject = PassthroughSubject()
        festivalsTappedSubject = PassthroughSubject()
        chantTappedSubject = PassthroughSubject()
        shareTappedSubject = PassthroughSubject()
        sutraTappedSubject = PassthroughSubject()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        retryTappedSubject = nil
        backTappedSubject = nil
        biographyToggledSubject = nil
        vowsToggledSubject = nil
        festivalsTappedSubject = nil
        chantTappedSubject = nil
        shareTappedSubject = nil
        sutraTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    // MARK: - Helpers
    private func makeSUT() {
        sut = ILDeityViewModel(useCase: mockUseCase, deityID: "bodhisattva_avalokitesvara")
    }

    private func makeInput() -> ILDeityViewModel.Input {
        ILDeityViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            biographyToggled: biographyToggledSubject.eraseToAnyPublisher(),
            vowsToggled: vowsToggledSubject.eraseToAnyPublisher(),
            festivalsTapped: festivalsTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            sutraTapped: sutraTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Transforms and records every state.
    private func observeStates(_ states: @escaping (ViewState<ILDeityStateModel>) -> Void) {
        sut.transform(input: makeInput()).state
            .sink(receiveValue: states)
            .store(in: &cancellables)
    }

    /// Transforms without loading; returns a getter for the latest `.success`.
    private func observeLatestState() -> () -> ILDeityStateModel? {
        var latest: ILDeityStateModel?
        observeStates { state in
            if case .success(let model) = state { latest = model }
        }
        return { latest }
    }

    /// Sends `viewDidLoad` and waits for the first `.success`; returns a getter for the latest one.
    private func loadSuccessfully() -> () -> ILDeityStateModel? {
        var latest: ILDeityStateModel?
        let loaded = expectation(description: "deity loaded")
        loaded.assertForOverFulfill = false
        observeStates { state in
            if case .success(let model) = state {
                latest = model
                loaded.fulfill()
            }
        }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)
        return { latest }
    }

    private func observeNavigation() -> () -> [ILDeityNavEvent] {
        var events: [ILDeityNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - Loading
    func test_viewDidLoad_emitsLoadingThenSuccess_andRequestsDeityID() {
        makeSUT()
        var states: [ViewState<ILDeityStateModel>] = []
        let loaded = expectation(description: "deity loaded")
        observeStates { state in
            states.append(state)
            if case .success = state { loaded.fulfill() }
        }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)

        XCTAssertEqual(mockUseCase.requestedIDs, ["bodhisattva_avalokitesvara"])
        guard states.count == 3 else { return XCTFail("expected idle → loading → success, got \(states)") }
        if case .idle = states[0] {} else { XCTFail("expected .idle first") }
        if case .loading = states[1] {} else { XCTFail("expected .loading second") }
    }

    func test_viewDidLoad_failure_emitsFailureWithUseCaseError() {
        mockUseCase.loadError = ILCatalogError.offline
        makeSUT()
        var failure: Error?
        let failed = expectation(description: "deity failed")
        observeStates { state in
            if case .failure(let error) = state {
                failure = error
                failed.fulfill()
            }
        }

        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 1)

        guard case ILCatalogError.offline? = failure else { return XCTFail("expected .offline, got \(String(describing: failure))") }
    }

    func test_retryTapped_afterFailure_loadsAgain() {
        mockUseCase.loadError = ILCatalogError.offline
        makeSUT()
        var latest: ILDeityStateModel?
        let failed = expectation(description: "deity failed")
        let loaded = expectation(description: "deity loaded")
        observeStates { state in
            switch state {
            case .failure: failed.fulfill()
            case .success(let model):
                latest = model
                loaded.fulfill()
            default: break
            }
        }
        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 1)

        mockUseCase.loadError = nil
        retryTappedSubject.send(())
        wait(for: [loaded], timeout: 1)

        XCTAssertEqual(mockUseCase.requestedIDs.count, 2)
        XCTAssertEqual(latest?.name, "Quán Thế Âm Bồ Tát")
    }

    func test_actionsBeforeLoad_areIgnored() {
        makeSUT()
        let events = observeNavigation()
        let latest = observeLatestState()

        biographyToggledSubject.send(())
        chantTappedSubject.send(0)

        XCTAssertNil(latest())
        XCTAssertEqual(events(), [])
    }

    // MARK: - Mapping
    func test_viewDidLoad_mapsHeroAndBody() {
        makeSUT()
        let latest = loadSuccessfully()

        let state = latest()
        XCTAssertEqual(state?.name, "Quán Thế Âm Bồ Tát")
        XCTAssertEqual(state?.headerTitle, "Quán Thế Âm Bồ Tát")
        XCTAssertEqual(state?.kind, .bodhisattva)
        XCTAssertEqual(state?.kindLabel, "deity.kind.bodhisattva".localized)
        XCTAssertEqual(state?.realmLabel, "Tây Phương Cực Lạc")
        XCTAssertEqual(state?.sanskritName, "Avalokiteśvara")
        XCTAssertEqual(state?.watermark, "觀世音")
        XCTAssertEqual(state?.roleText, "Đại Bi")
        XCTAssertEqual(state?.biography, "Tiểu sử")
    }

    func test_memorialDay_formatsTileAndCountdown() {
        makeSUT()
        let latest = loadSuccessfully()

        let memorialDay = latest()?.memorialDay
        XCTAssertEqual(memorialDay?.dayText, "19")
        XCTAssertEqual(memorialDay?.monthText, String(format: "deity.memorial.monthFormat".localized, 2))
        XCTAssertEqual(memorialDay?.eventName, "Vía đản sinh")
        // 2026-04-06 (UTC+7) là Thứ Hai.
        let expected = String(
            format: "deity.memorial.dateFormat".localized,
            String(format: "deity.memorial.daysLeft".localized, 12),
            String(format: "deity.weekday.format".localized, 2),
            "06-04-2026"
        )
        XCTAssertEqual(memorialDay?.countdownText, expected)
    }

    func test_memorialDay_isNilWhenUseCaseHasNone() {
        mockUseCase.upcoming = nil
        makeSUT()
        let latest = loadSuccessfully()

        XCTAssertNil(latest()?.memorialDay)
    }

    func test_mantras_skipEmptyCardsAndKeepOrder() {
        makeSUT()
        let latest = loadSuccessfully()

        let mantras = latest()?.mantras ?? []
        XCTAssertEqual(mantras.map(\.label), [
            "deity.mantra.label.title".localized,
            "deity.mantra.label.short".localized
        ])
        XCTAssertEqual(mantras.first?.text, "Nam Mô Đại Từ Đại Bi Quán Thế Âm Bồ Tát")
        XCTAssertEqual(mantras.last?.sanskrit, "Oṃ Maṇi Padme Hūṃ")
    }

    func test_sutras_onlyLibrarySutraHasOpenAction() {
        makeSUT()
        let latest = loadSuccessfully()

        let sutras = latest()?.sutras ?? []
        XCTAssertEqual(sutras.count, 2)
        XCTAssertEqual(sutras[0].trailingText, "deity.sutra.open".localized)
        XCTAssertEqual(sutras[0].sutraID, "a-di-da")
        XCTAssertEqual(sutras[1].trailingText, "")
        XCTAssertNil(sutras[1].sutraID)
    }

    // MARK: - Toggles
    func test_biographyToggle_flipsExpandedState() {
        makeSUT()
        let latest = loadSuccessfully()
        XCTAssertEqual(latest()?.isBiographyExpanded, false)
        XCTAssertEqual(latest()?.biographyToggleTitle, "deity.biography.expand".localized)

        biographyToggledSubject.send(())

        XCTAssertEqual(latest()?.isBiographyExpanded, true)
        XCTAssertEqual(latest()?.biographyToggleTitle, "deity.biography.collapse".localized)
    }

    func test_vows_collapseToFiveAndExpandOnToggle() {
        mockUseCase.vows = (1...7).map { "Nguyện \($0)" }
        makeSUT()
        let latest = loadSuccessfully()

        XCTAssertEqual(latest()?.vows.count, ILDeityViewModel.collapsedVowLimit)
        XCTAssertEqual(latest()?.vowsCountText, String(format: "deity.vows.countFormat".localized, 7))
        XCTAssertEqual(latest()?.vowsToggleTitle, String(format: "deity.vows.expandFormat".localized, 7))

        vowsToggledSubject.send(())

        XCTAssertEqual(latest()?.vows.count, 7)
        XCTAssertEqual(latest()?.vows.last, ILDeityVowModel(number: "7", text: "Nguyện 7"))
        XCTAssertEqual(latest()?.vowsToggleTitle, "deity.vows.collapse".localized)
    }

    func test_vows_noToggleWhenFiveOrFewer() {
        makeSUT()
        let latest = loadSuccessfully()

        XCTAssertEqual(latest()?.vows.count, 2)
        XCTAssertNil(latest()?.vowsToggleTitle)
    }

    // MARK: - Navigation
    func test_backTapped_emitsBack() {
        makeSUT()
        let events = observeNavigation()
        _ = observeLatestState()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.back])
    }

    func test_festivalsTapped_emitsOpenFestivals() {
        makeSUT()
        let events = observeNavigation()
        _ = observeLatestState()

        festivalsTappedSubject.send(())

        XCTAssertEqual(events(), [.openFestivals])
    }

    func test_chantTapped_opensMalaWithMantraText() {
        makeSUT()
        let events = observeNavigation()
        _ = loadSuccessfully()

        chantTappedSubject.send(1)
        chantTappedSubject.send(99)

        XCTAssertEqual(events(), [.openMala(mantraText: "Án Ma Ni Bát Di Hồng")])
    }

    func test_shareTapped_sharesMantraSanskritAndName() {
        makeSUT()
        let events = observeNavigation()
        _ = loadSuccessfully()

        shareTappedSubject.send(1)

        XCTAssertEqual(events(), [.share(text: "Án Ma Ni Bát Di Hồng\nOṃ Maṇi Padme Hūṃ\nQuán Thế Âm Bồ Tát")])
    }

    func test_sutraTapped_opensOnlyLibrarySutra() {
        makeSUT()
        let events = observeNavigation()
        _ = loadSuccessfully()

        sutraTappedSubject.send(1)
        sutraTappedSubject.send(0)

        XCTAssertEqual(events(), [.openSutra(id: "a-di-da")])
    }
}

// MARK: - ILDeityUseCaseImpl

final class ILDeityUseCaseTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        return calendar
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9)) ?? Date()
    }

    private func makeSUT(now: @escaping () -> Date = Date.init) -> ILDeityUseCaseImpl {
        ILDeityUseCaseImpl(deityCatalogRepository: repository, now: now)
    }

    private let repository = StubILDeityCatalogRepository()

    /// A deity from the static catalog behind `getAllDeities()`.
    private func catalogDeity(_ id: String) throws -> ILDeityEntity {
        try XCTUnwrap(makeSUT().getAllDeities().first { $0.id == id })
    }

    // MARK: - loadDeity

    func test_loadDeity_returnsRepositoryDetailForID() async throws {
        let expected = try catalogDeity("buddha_amitabha")
        repository.detailResult = .success(expected)

        let deity = try await makeSUT().loadDeity(id: "buddha_amitabha")

        XCTAssertEqual(deity, expected)
        XCTAssertEqual(repository.requestedDetailIDs, ["buddha_amitabha"])
    }

    func test_loadDeity_propagatesRepositoryError() async {
        repository.detailResult = .failure(ILCatalogError.notFound)

        do {
            _ = try await makeSUT().loadDeity(id: "nope")
            XCTFail("expected an error")
        } catch {
            guard case ILCatalogError.notFound = error else { return XCTFail("expected .notFound, got \(error)") }
        }
    }

    // MARK: - Memorial day / sutras

    func test_upcomingMemorialDay_returnsNearestLunarMatch() throws {
        let sut = makeSUT(now: { self.makeDate(2026, 3, 25) })
        let deity = try catalogDeity("buddha_shakyamuni")

        let upcoming = try XCTUnwrap(sut.upcomingMemorialDay(for: deity))

        let lunar = ILLunarCalendar.solarToLunar(date: upcoming.date, calendar: calendar)
        XCTAssertEqual(lunar.month, upcoming.memorialDay.lunarMonth)
        XCTAssertEqual(lunar.day, upcoming.memorialDay.lunarDay)
        // Không có ngày vía nào khác của vị này rơi vào trước kết quả.
        for offset in 0..<upcoming.daysUntil {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: makeDate(2026, 3, 25)))
            let other = ILLunarCalendar.solarToLunar(date: date, calendar: calendar)
            XCTAssertFalse(deity.memorialDays.contains {
                $0.lunarDay == other.day && $0.lunarMonth == other.month && !other.isLeapMonth
            })
        }
    }

    func test_upcomingMemorialDay_isTodayWhenDatesMatch() throws {
        let sut = makeSUT(now: { self.makeDate(2026, 3, 25) })
        let deity = try catalogDeity("buddha_shakyamuni")
        let first = try XCTUnwrap(sut.upcomingMemorialDay(for: deity))

        let sameDaySUT = makeSUT(now: { first.date })
        let sameDay = try XCTUnwrap(sameDaySUT.upcomingMemorialDay(for: deity))

        XCTAssertEqual(sameDay.daysUntil, 0)
        XCTAssertEqual(sameDay.memorialDay, first.memorialDay)
    }

    func test_upcomingMemorialDay_day30FallsBackToLastDayOfShortMonth() throws {
        let sut = makeSUT(now: { self.makeDate(2026, 9, 28) })
        let deity = try catalogDeity("buddha_bhaisajyaguru")

        let upcoming = try XCTUnwrap(sut.upcomingMemorialDay(for: deity))

        let lunar = ILLunarCalendar.solarToLunar(date: upcoming.date, calendar: calendar)
        XCTAssertEqual(lunar.month, 9)
        XCTAssertTrue(lunar.day == 30 || lunar.day == 29)
        let nextDate = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: upcoming.date))
        XCTAssertEqual(ILLunarCalendar.solarToLunar(date: nextDate, calendar: calendar).day, 1)
    }

    func test_relatedSutras_splitsCanonicalSourceOutsideParentheses() throws {
        let sut = makeSUT()
        let deity = try catalogDeity("buddha_amitabha")

        let sutras = sut.relatedSutras(for: deity)

        XCTAssertEqual(sutras.map(\.title), ["Kinh Vô Lượng Thọ", "Kinh A Di Đà", "Kinh Quán Vô Lượng Thọ"])
        XCTAssertEqual(sutras.map(\.sutraID), [nil, "a-di-da", nil])
    }

    func test_canonicalSources_keepsCommasInsideParentheses() throws {
        let deity = try catalogDeity("buddha_shakyamuni")

        XCTAssertEqual(deity.canonicalSources, [
            "Trường Bộ Kinh (Dīgha Nikāya)",
            "Kinh Phổ Diệu (Lalitavistara Sūtra)"
        ])
    }
}

// MARK: - Mock

final class MockILDeityUseCase: ILDeityUseCase {

    var vows = [
        "Nguyện cứu khổ cứu nạn.",
        "Nguyện lắng nghe tiếng kêu của chúng sinh."
    ]

    var upcoming: ILDeityUpcomingMemorialDayEntity? = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 4, day: 6, hour: 12)) ?? Date()
        return ILDeityUpcomingMemorialDayEntity(
            memorialDay: ILDeityMemorialDayEntity(lunarDay: 19, lunarMonth: 2, eventName: "Vía đản sinh"),
            date: date,
            daysUntil: 12
        )
    }()

    /// Set to make `loadDeity(id:)` throw.
    var loadError: Error?
    private(set) var requestedIDs: [String] = []

    func loadDeity(id: String) async throws -> ILDeityEntity {
        requestedIDs.append(id)
        if let loadError { throw loadError }
        return makeDeity(id: id)
    }

    func makeDeity(id deityID: String) -> ILDeityEntity {
        ILDeityEntity(
            id: deityID,
            kind: .bodhisattva,
            nameVi: "Quán Thế Âm Bồ Tát",
            nameSanskrit: "Avalokiteśvara",
            nameChinese: "觀世音",
            titleHonorific: "Nam Mô Đại Từ Đại Bi Quán Thế Âm Bồ Tát",
            canonicalSource: "Kinh A Di Đà, Kinh Lăng Nghiêm",
            coreVirtue: "Đại Bi",
            pureLand: "Tây Phương Cực Lạc",
            memorialDays: [ILDeityMemorialDayEntity(lunarDay: 19, lunarMonth: 2, eventName: "Vía đản sinh")],
            iconography: ILDeityIconographyEntity(posture: "", mountOrThrone: "", sacredArtifacts: [], symbolicMeaning: ""),
            biographySummary: "Tiểu sử",
            greatVows: vows,
            mantra: ILDeityMantraEntity(
                shortSanskrit: "Oṃ Maṇi Padme Hūṃ",
                shortSinoVietnamese: "Án Ma Ni Bát Di Hồng",
                dharaniName: "Chú Đại Bi",
                dharaniSnippet: ""
            )
        )
    }

    func getAllDeities() -> [ILDeityEntity] {
        [makeDeity(id: "bodhisattva_avalokitesvara")]
    }

    func upcomingMemorialDay(for deity: ILDeityEntity) -> ILDeityUpcomingMemorialDayEntity? {
        upcoming
    }

    func relatedSutras(for deity: ILDeityEntity) -> [ILDeityRelatedSutraEntity] {
        [
            ILDeityRelatedSutraEntity(title: "Kinh A Di Đà", sutraID: "a-di-da"),
            ILDeityRelatedSutraEntity(title: "Kinh Lăng Nghiêm", sutraID: nil)
        ]
    }
}

/// `ILDeityCatalogRepository` stub for tests that build a real `ILDeityUseCaseImpl` — only the
/// detail and top calls are configurable; the paged list returns an empty result.
final class StubILDeityCatalogRepository: ILDeityCatalogRepository {

    var detailResult: Result<ILDeityEntity, Error> = .failure(ILCatalogError.notFound)
    var topResult: Result<[ILDeitySummaryEntity], Error> = .success([])
    private(set) var requestedDetailIDs: [String] = []

    func loadTopDeities() async throws -> [ILDeitySummaryEntity] {
        try topResult.get()
    }

    func loadDeities(page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity> {
        ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadDeityDetail(id: String) async throws -> ILDeityEntity {
        requestedDetailIDs.append(id)
        return try detailResult.get()
    }
}
