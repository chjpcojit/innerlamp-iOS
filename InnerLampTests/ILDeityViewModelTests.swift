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
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            biographyToggled: biographyToggledSubject.eraseToAnyPublisher(),
            vowsToggled: vowsToggledSubject.eraseToAnyPublisher(),
            festivalsTapped: festivalsTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            sutraTapped: sutraTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILDeityStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILDeityStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    private func observeNavigation() -> () -> [ILDeityNavEvent] {
        var events: [ILDeityNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - Mapping
    func test_viewDidLoad_mapsHeroAndBody() {
        makeSUT()
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

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
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

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
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.memorialDay)
    }

    func test_mantras_skipEmptyCardsAndKeepOrder() {
        makeSUT()
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

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
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let sutras = latest()?.sutras ?? []
        XCTAssertEqual(sutras.count, 2)
        XCTAssertEqual(sutras[0].trailingText, "deity.sutra.open".localized)
        XCTAssertEqual(sutras[0].sutraID, "sutra.amida")
        XCTAssertEqual(sutras[1].trailingText, "")
        XCTAssertNil(sutras[1].sutraID)
    }

    // MARK: - Toggles
    func test_biographyToggle_flipsExpandedState() {
        makeSUT()
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, false)
        XCTAssertEqual(latest()?.biographyToggleTitle, "deity.biography.expand".localized)

        biographyToggledSubject.send(())

        XCTAssertEqual(latest()?.isBiographyExpanded, true)
        XCTAssertEqual(latest()?.biographyToggleTitle, "deity.biography.collapse".localized)
    }

    func test_vows_collapseToFiveAndExpandOnToggle() {
        mockUseCase.vows = (1...7).map { "Nguyện \($0)" }
        makeSUT()
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

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
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

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
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        chantTappedSubject.send(1)
        chantTappedSubject.send(99)

        XCTAssertEqual(events(), [.openMala(mantraText: "Án Ma Ni Bát Di Hồng")])
    }

    func test_shareTapped_sharesMantraSanskritAndName() {
        makeSUT()
        let events = observeNavigation()
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        shareTappedSubject.send(1)

        XCTAssertEqual(events(), [.share(text: "Án Ma Ni Bát Di Hồng\nOṃ Maṇi Padme Hūṃ\nQuán Thế Âm Bồ Tát")])
    }

    func test_sutraTapped_opensOnlyLibrarySutra() {
        makeSUT()
        let events = observeNavigation()
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        sutraTappedSubject.send(1)
        sutraTappedSubject.send(0)

        XCTAssertEqual(events(), [.openSutra(id: "sutra.amida")])
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

    func test_upcomingMemorialDay_returnsNearestLunarMatch() throws {
        let sut = ILDeityUseCaseImpl(now: { self.makeDate(2026, 3, 25) })
        let deity = sut.getInitialState(deityID: "buddha_shakyamuni")

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
        let sut = ILDeityUseCaseImpl(now: { self.makeDate(2026, 3, 25) })
        let deity = sut.getInitialState(deityID: "buddha_shakyamuni")
        let first = try XCTUnwrap(sut.upcomingMemorialDay(for: deity))

        let sameDaySUT = ILDeityUseCaseImpl(now: { first.date })
        let sameDay = try XCTUnwrap(sameDaySUT.upcomingMemorialDay(for: deity))

        XCTAssertEqual(sameDay.daysUntil, 0)
        XCTAssertEqual(sameDay.memorialDay, first.memorialDay)
    }

    func test_upcomingMemorialDay_day30FallsBackToLastDayOfShortMonth() throws {
        let sut = ILDeityUseCaseImpl(now: { self.makeDate(2026, 9, 28) })
        let deity = sut.getInitialState(deityID: "buddha_bhaisajyaguru")

        let upcoming = try XCTUnwrap(sut.upcomingMemorialDay(for: deity))

        let lunar = ILLunarCalendar.solarToLunar(date: upcoming.date, calendar: calendar)
        XCTAssertEqual(lunar.month, 9)
        XCTAssertTrue(lunar.day == 30 || lunar.day == 29)
        let nextDate = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: upcoming.date))
        XCTAssertEqual(ILLunarCalendar.solarToLunar(date: nextDate, calendar: calendar).day, 1)
    }

    func test_relatedSutras_splitsCanonicalSourceOutsideParentheses() {
        let sut = ILDeityUseCaseImpl()
        let deity = sut.getInitialState(deityID: "buddha_amitabha")

        let sutras = sut.relatedSutras(for: deity)

        XCTAssertEqual(sutras.map(\.title), ["Kinh Vô Lượng Thọ", "Kinh A Di Đà", "Kinh Quán Vô Lượng Thọ"])
        XCTAssertEqual(sutras.map(\.sutraID), [nil, "sutra.amida", nil])
    }

    func test_canonicalSources_keepsCommasInsideParentheses() {
        let deity = ILDeityUseCaseImpl().getInitialState(deityID: "buddha_shakyamuni")

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

    func getInitialState(deityID: String) -> ILDeityEntity {
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
        [getInitialState(deityID: "bodhisattva_avalokitesvara")]
    }

    func upcomingMemorialDay(for deity: ILDeityEntity) -> ILDeityUpcomingMemorialDayEntity? {
        upcoming
    }

    func relatedSutras(for deity: ILDeityEntity) -> [ILDeityRelatedSutraEntity] {
        [
            ILDeityRelatedSutraEntity(title: "Kinh A Di Đà", sutraID: "sutra.amida"),
            ILDeityRelatedSutraEntity(title: "Kinh Lăng Nghiêm", sutraID: nil)
        ]
    }
}
