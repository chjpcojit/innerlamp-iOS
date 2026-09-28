//
//  ILHomeViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILHomeViewModelTests: XCTestCase {

    private var mockUseCase: MockILHomeUseCase!
    private var sut: ILHomeViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var beadTappedSubject: PassthroughSubject<Void, Never>!
    private var resetBeadsTappedSubject: PassthroughSubject<Void, Never>!
    private var malaFullscreenTappedSubject: PassthroughSubject<Void, Never>!
    private var lunarCalendarTappedSubject: PassthroughSubject<Void, Never>!
    private var lunarHeroTappedSubject: PassthroughSubject<Void, Never>!
    private var dayTappedSubject: PassthroughSubject<String, Never>!
    private var photosTappedSubject: PassthroughSubject<Void, Never>!
    private var bellTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var articleTappedSubject: PassthroughSubject<String, Never>!
    private var articlesViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var templeTappedSubject: PassthroughSubject<String, Never>!
    private var deityTappedSubject: PassthroughSubject<String, Never>!
    private var deitiesViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var suggestedSessionTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILHomeUseCase()
        mockUseCase.loadBuddhistEventMonthsResult = mockUseCase.stubEntity.eventMonths
        sut = ILHomeViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        beadTappedSubject = PassthroughSubject<Void, Never>()
        resetBeadsTappedSubject = PassthroughSubject<Void, Never>()
        malaFullscreenTappedSubject = PassthroughSubject<Void, Never>()
        lunarCalendarTappedSubject = PassthroughSubject<Void, Never>()
        lunarHeroTappedSubject = PassthroughSubject<Void, Never>()
        dayTappedSubject = PassthroughSubject<String, Never>()
        photosTappedSubject = PassthroughSubject<Void, Never>()
        bellTappedSubject = PassthroughSubject<Void, Never>()
        eventsTappedSubject = PassthroughSubject<Void, Never>()
        articleTappedSubject = PassthroughSubject<String, Never>()
        articlesViewAllTappedSubject = PassthroughSubject<Void, Never>()
        templeTappedSubject = PassthroughSubject<String, Never>()
        deityTappedSubject = PassthroughSubject<String, Never>()
        deitiesViewAllTappedSubject = PassthroughSubject<Void, Never>()
        suggestedSessionTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        beadTappedSubject = nil
        resetBeadsTappedSubject = nil
        malaFullscreenTappedSubject = nil
        lunarCalendarTappedSubject = nil
        lunarHeroTappedSubject = nil
        dayTappedSubject = nil
        photosTappedSubject = nil
        bellTappedSubject = nil
        eventsTappedSubject = nil
        articleTappedSubject = nil
        articlesViewAllTappedSubject = nil
        templeTappedSubject = nil
        deityTappedSubject = nil
        deitiesViewAllTappedSubject = nil
        suggestedSessionTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILHomeViewModel.Input {
        ILHomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadTapped: beadTappedSubject.eraseToAnyPublisher(),
            resetBeadsTapped: resetBeadsTappedSubject.eraseToAnyPublisher(),
            malaFullscreenTapped: malaFullscreenTappedSubject.eraseToAnyPublisher(),
            lunarCalendarTapped: lunarCalendarTappedSubject.eraseToAnyPublisher(),
            lunarHeroTapped: lunarHeroTappedSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            photosTapped: photosTappedSubject.eraseToAnyPublisher(),
            bellTapped: bellTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            articleTapped: articleTappedSubject.eraseToAnyPublisher(),
            articlesViewAllTapped: articlesViewAllTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            deitiesViewAllTapped: deitiesViewAllTappedSubject.eraseToAnyPublisher(),
            suggestedSessionTapped: suggestedSessionTappedSubject.eraseToAnyPublisher()
        )
    }

    func test_initialState_matchesUseCaseDefault() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(receivedState?.malaCount, mockUseCase.stubEntity.malaCount)
        XCTAssertEqual(receivedState?.malaGoal, mockUseCase.stubEntity.malaGoal)
        XCTAssertEqual(receivedState?.streakDays, mockUseCase.stubEntity.streakDays)
        XCTAssertEqual(receivedState?.lunarHero.verseLines, mockUseCase.stubEntity.lunarDate.verse.lines)
        XCTAssertEqual(receivedState?.weekPages.count, mockUseCase.stubEntity.weekPages.count)
        XCTAssertEqual(receivedState?.weekPages.first?.days.count, mockUseCase.stubEntity.weekPages.first?.days.count)
        XCTAssertEqual(receivedState?.eventMonths.count, mockUseCase.stubEntity.eventMonths.count)
        XCTAssertEqual(receivedState?.suggestedSessions.count, mockUseCase.stubEntity.suggestedSessions.count)
        XCTAssertEqual(receivedState?.photos.count, mockUseCase.stubEntity.photos.count)
        XCTAssertEqual(receivedState?.photosMoreText, String(format: "home.photos.moreFormat".localized, max(0, mockUseCase.stubEntity.photos.count - 3)))
        XCTAssertEqual(receivedState?.temples.count, mockUseCase.stubEntity.temples.count)
        XCTAssertEqual(receivedState?.temples.first?.name, mockUseCase.stubEntity.temples.first?.name)
        XCTAssertEqual(receivedState?.bellTitle, "home.bell.title".localized)
        XCTAssertEqual(receivedState?.bellSubtitle, "home.bell.subtitle".localized)
        XCTAssertEqual(receivedState?.articles.count, mockUseCase.stubEntity.articles.count)
        XCTAssertEqual(receivedState?.articles.first?.readText, String(format: "home.article.readFormat".localized, mockUseCase.stubEntity.articles.first?.readMinutes ?? 0))
    }

    func test_initialState_capsEventMonthCardEventsToThree() {
        let today = Date()
        let events = (1...5).map { index in
            ILHomeEventItemEntity(
                id: "event-\(index)",
                date: today,
                title: "Event \(index)",
                lunarLabel: "Lunar \(index)",
                tone: .gold
            )
        }
        mockUseCase.stubEntity.eventMonths = [
            ILHomeEventMonthEntity(id: "month-many", monthLabel: "Tháng nhiều sự kiện", events: events)
        ]
        mockUseCase.loadBuddhistEventMonthsResult = mockUseCase.stubEntity.eventMonths

        let output = sut.transform(input: makeInput())
        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertEqual(receivedState?.eventMonths.first?.events.count, 3)
        XCTAssertEqual(receivedState?.eventMonths.first?.totalEventsCount, 5)
    }

    func test_initialState_marksCardMatchingCurrentMonthAsCurrent() {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: Date())
        let currentMonthKey = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)

        mockUseCase.stubEntity.eventMonths = [
            ILHomeEventMonthEntity(id: "1999-01", monthLabel: "Tháng khác", events: []),
            ILHomeEventMonthEntity(id: currentMonthKey, monthLabel: "Tháng hiện tại", events: [])
        ]
        mockUseCase.loadBuddhistEventMonthsResult = mockUseCase.stubEntity.eventMonths

        let output = sut.transform(input: makeInput())
        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertEqual(receivedState?.eventMonths.map(\.isCurrentMonth), [false, true])
    }

    func test_initialState_withEmptyDisplayName_fallsBackToGuestGreeting() {
        mockUseCase.stubEntity.displayName = ""
        let output = sut.transform(input: makeInput())

        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        let expectedGreeting = String(format: "home.greeting.format".localized, "home.greeting.name.guest".localized)
        XCTAssertEqual(receivedState?.greetingText, expectedGreeting)
    }

    func test_beadTapped_incrementsMalaCountThroughUseCase() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        beadTappedSubject.send(())

        XCTAssertTrue(mockUseCase.incrementBeadCalled)
        XCTAssertEqual(receivedState?.malaCount, 1)
    }

    func test_resetBeadsTapped_resetsMalaCountThroughUseCase() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        beadTappedSubject.send(())
        resetBeadsTappedSubject.send(())

        XCTAssertTrue(mockUseCase.resetBeadsCalled)
        XCTAssertEqual(receivedState?.malaCount, 0)
    }

    func test_malaFullscreenTapped_firesOpenMalaNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        malaFullscreenTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openMala)
    }

    func test_lunarCalendarTapped_firesOpenLunarCalendarNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        lunarCalendarTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openLunarCalendar)
    }

    func test_lunarHeroTapped_firesOpenLunarDayDetailWithSelectedDate() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        lunarHeroTappedSubject.send(())

        let selectedDate = mockUseCase.stubEntity.weekPages.flatMap(\.days).first(where: { $0.id == "today" })?.date
        XCTAssertEqual(
            receivedEvent,
            selectedDate.map { .openLunarDayDetail(date: $0, verse: mockUseCase.stubEntity.lunarDate.verse) }
        )
    }

    func test_lunarHeroTapped_passesNilVerse_whileQuoteNotLoaded() {
        mockUseCase.stubEntity.lunarDate.verse = ILHomeQuoteEntity()
        sut = ILHomeViewModel(useCase: mockUseCase)
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        lunarHeroTappedSubject.send(())

        guard case .openLunarDayDetail(_, let verse) = receivedEvent else {
            return XCTFail("Expected openLunarDayDetail, got \(String(describing: receivedEvent))")
        }
        XCTAssertNil(verse)
    }

    func test_dayTapped_selectsDayAndUpdatesLunarHero() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        dayTappedSubject.send("day-2")

        XCTAssertEqual(mockUseCase.selectDayCalledWithID, "day-2")
        XCTAssertEqual(receivedState?.lunarHero.lunarDay, 17)
        XCTAssertEqual(receivedState?.weekPages.first?.days.first(where: { $0.id == "day-2" })?.isSelected, true)
        XCTAssertEqual(receivedState?.weekPages.first?.days.first(where: { $0.id == "today" })?.isSelected, false)
    }

    func test_viewDidLoad_showsRandomVerseOnLunarHero() {
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "random verse applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.lunarHero.verseLines == ["Random verse"] {
                    XCTAssertEqual(model.lunarHero.verseSource, "— Kinh Pháp Cú (Dhammapada), câu 5")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_dayTapped_sameDay_doesNotCallSelectDay() {
        _ = sut.transform(input: makeInput())

        viewDidLoadSubject.send(())
        dayTappedSubject.send("today")

        XCTAssertNil(mockUseCase.selectDayCalledWithID)
    }

    func test_weekDayDotKind_mapsLunarDayAndHoangDao() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        mockUseCase.stubEntity.weekPages = [
            ILHomeWeekPageEntity(
                id: "week",
                label: "Tháng 9, 2026",
                days: [
                    ILHomeWeekDayEntity(id: "mung1", date: today, solarDay: 1, lunarDay: 1, lunarMonth: 7, isHoangDao: false, isToday: false),
                    ILHomeWeekDayEntity(id: "ram", date: tomorrow, solarDay: 2, lunarDay: 15, lunarMonth: 7, isHoangDao: false, isToday: false),
                    ILHomeWeekDayEntity(id: "hoangdao", date: today, solarDay: 3, lunarDay: 5, lunarMonth: 7, isHoangDao: true, isToday: false),
                    ILHomeWeekDayEntity(id: "hacdao", date: tomorrow, solarDay: 4, lunarDay: 6, lunarMonth: 7, isHoangDao: false, isToday: false)
                ]
            )
        ]
        mockUseCase.stubEntity.selectedDayID = "mung1"
        sut = ILHomeViewModel(useCase: mockUseCase)

        let output = sut.transform(input: makeInput())
        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        let days = receivedState?.weekPages.first?.days ?? []
        XCTAssertEqual(days.first(where: { $0.id == "mung1" })?.dotKind, .newMoonFullMoon)
        XCTAssertEqual(days.first(where: { $0.id == "ram" })?.dotKind, .newMoonFullMoon)
        XCTAssertEqual(days.first(where: { $0.id == "hoangdao" })?.dotKind, .hoangDao)
        XCTAssertEqual(days.first(where: { $0.id == "hacdao" })?.dotKind, .hacDao)
    }

    func test_photosTapped_firesOpenPhotosNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        photosTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openPhotos)
    }

    func test_bellTapped_firesOpenBellNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        bellTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openBell)
    }

    func test_eventsTapped_firesOpenFestivalsNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        eventsTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openFestivals)
    }

    func test_articleTapped_firesOpenArticleNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        articleTappedSubject.send("art-1")

        XCTAssertEqual(receivedEvent, .openArticle(id: "art-1"))
    }

    func test_templeTapped_firesOpenTempleNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        templeTappedSubject.send("tp-motcot")

        XCTAssertEqual(receivedEvent, .openTemple(id: "tp-motcot"))
    }

    func test_deityTapped_firesOpenDeityNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        deityTappedSubject.send("buddha_shakyamuni")

        XCTAssertEqual(receivedEvent, .openDeity(id: "buddha_shakyamuni"))
    }

    func test_deitiesViewAllTapped_firesOpenDeitiesNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        deitiesViewAllTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openDeities)
    }

    func test_initialState_mapsDeityKindLabelAndMemorialText() {
        let output = sut.transform(input: makeInput())
        var receivedState: ILHomeStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { receivedState = model }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertEqual(receivedState?.deitiesTitle, "home.deity.title".localized)
        XCTAssertEqual(receivedState?.deitiesViewAllText, "home.deity.viewAll".localized)
        XCTAssertEqual(receivedState?.deities.count, 2)
        XCTAssertEqual(receivedState?.deities.first?.kindLabel, "deity.kind.buddha".localized)
        XCTAssertEqual(receivedState?.deities.first?.memorialText, String(format: "home.deity.memorialFormat".localized, 15, 4))
        XCTAssertEqual(receivedState?.deities.last?.kindLabel, "deity.kind.bodhisattva".localized)
        XCTAssertEqual(receivedState?.deities.last?.memorialText, "", "No memorial day → empty line (hidden)")
    }

    func test_suggestedSessionTapped_meditationKind_firesOpenMeditationSetupNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        suggestedSessionTappedSubject.send("breathing")

        XCTAssertEqual(receivedEvent, .openMeditationSetup)
    }

    func test_suggestedSessionTapped_nonMeditationKind_firesNoNavigationEvent() {
        mockUseCase.stubEntity.suggestedSessions.append(
            ILHomeSuggestedSessionEntity(
                id: "sutra",
                kind: .sutra,
                title: "home.session.sutra.title".localized,
                subtitle: "home.session.sutra.subtitle".localized,
                trailingText: "home.session.sutra.trailing".localized,
                tone: .gold,
                glyph: .book
            )
        )
        sut = ILHomeViewModel(useCase: mockUseCase)
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        suggestedSessionTappedSubject.send("sutra")
        suggestedSessionTappedSubject.send("unknown-id")

        XCTAssertNil(receivedEvent)
    }
}

// MARK: - Mock ILHomeUseCase
final class MockILHomeUseCase: ILHomeUseCase {
    var stubEntity: ILHomeEntity = {
        var entity = ILHomeEntity()
        entity.displayName = "Tâm An"

        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        entity.weekPages = [
            ILHomeWeekPageEntity(
                id: "week-current",
                label: "Tháng 9, 2026",
                days: [
                    ILHomeWeekDayEntity(id: "today", date: today, solarDay: 10, lunarDay: 16, lunarMonth: 7, isHoangDao: true, isToday: true),
                    ILHomeWeekDayEntity(id: "day-2", date: tomorrow, solarDay: 11, lunarDay: 17, lunarMonth: 7, isHoangDao: false, isToday: false)
                ]
            )
        ]
        entity.selectedDayID = "today"
        entity.lunarDate = ILHomeLunarDateEntity(
            solarLabel: "Thứ Năm, 10 tháng 9",
            lunarDay: 16,
            lunarMonthLabel: "Tháng Bảy",
            lunarYearLabel: "Năm Giáp Thìn",
            verse: ILHomeQuoteEntity(
                lines: ["home.lunar.verse.line1".localized, "home.lunar.verse.line2".localized],
                source: "home.lunar.verse.source".localized
            )
        )
        entity.eventMonths = [
            ILHomeEventMonthEntity(
                id: "month-current",
                monthLabel: "Tháng 9",
                events: [
                    ILHomeEventItemEntity(id: "vu-lan", date: today, title: "home.events.vuLan.title".localized, lunarLabel: "home.events.vuLan.lunar".localized, tone: .gold)
                ]
            )
        ]

        entity.sessionMinutesDone = 12
        entity.sessionMinutesGoal = 20
        entity.streakDays = 42
        entity.streakWeekProgress = [0.3, 0.5, 0.7, 1.0, 0.4, 0.6, 1.0]
        entity.malaCount = 0
        entity.malaGoal = 108
        entity.malaMantraText = "home.mala.mantra".localized
        entity.suggestedSessions = [
            ILHomeSuggestedSessionEntity(
                id: "breathing",
                kind: .meditation,
                title: "home.session.breathing.title".localized,
                subtitle: "home.session.breathing.subtitle".localized,
                trailingText: "home.session.breathing.trailing".localized,
                tone: .green,
                glyph: .leaf
            )
        ]
        entity.photos = [
            ILHomePhotoEntity(id: "pg-1"),
            ILHomePhotoEntity(id: "pg-2"),
            ILHomePhotoEntity(id: "pg-3"),
            ILHomePhotoEntity(id: "pg-4")
        ]
        entity.temples = [
            ILHomeTempleEntity(
                id: "tp-motcot",
                name: "home.temple.motcot.name".localized,
                place: "home.temple.motcot.place".localized,
                region: "home.temple.motcot.region".localized,
                note: "home.temple.motcot.note".localized
            )
        ]
        entity.articles = [
            ILHomeArticleEntity(
                id: "art-1",
                category: "home.article.0.category".localized,
                title: "home.article.0.title".localized,
                author: "home.article.0.author".localized,
                readMinutes: 6
            )
        ]
        entity.deities = [
            ILHomeDeityEntity(
                id: "buddha_shakyamuni",
                kind: .buddha,
                name: "Thích Ca Mâu Ni Phật",
                honorific: "Bổn Sư Thích Ca Mâu Ni Phật",
                virtue: "Toàn Giác",
                memorialDay: ILDeityMemorialDayEntity(lunarDay: 15, lunarMonth: 4, eventName: "Phật Đản")
            ),
            ILHomeDeityEntity(
                id: "bodhisattva_test",
                kind: .bodhisattva,
                name: "Bồ Tát",
                honorific: "",
                virtue: "",
                memorialDay: nil
            )
        ]
        return entity
    }()

    var getInitialStateCalled = false
    func getInitialState() -> ILHomeEntity {
        getInitialStateCalled = true
        return stubEntity
    }

    var incrementBeadCalled = false
    func incrementBead(_ entity: ILHomeEntity) -> ILHomeEntity {
        incrementBeadCalled = true
        var newEntity = entity
        let next = entity.malaCount + 1
        newEntity.malaCount = next > entity.malaGoal ? 1 : next
        return newEntity
    }

    var resetBeadsCalled = false
    func resetBeads(_ entity: ILHomeEntity) -> ILHomeEntity {
        resetBeadsCalled = true
        var newEntity = entity
        newEntity.malaCount = 0
        return newEntity
    }

    var selectDayCalledWithID: String?
    func selectDay(id: String, in entity: ILHomeEntity) -> ILHomeEntity {
        selectDayCalledWithID = id
        var newEntity = entity
        guard let day = entity.weekPages.flatMap(\.days).first(where: { $0.id == id }) else {
            return entity
        }
        newEntity.selectedDayID = id
        newEntity.lunarDate.lunarDay = day.lunarDay
        return newEntity
    }

    var loadBuddhistEventMonthsCalled = false
    var loadBuddhistEventMonthsResult: [ILHomeEventMonthEntity] = []
    func loadBuddhistEventMonths(around date: Date) async throws -> [ILHomeEventMonthEntity] {
        loadBuddhistEventMonthsCalled = true
        return loadBuddhistEventMonthsResult
    }

    var loadRandomVerseResult = ILHomeQuoteEntity(lines: ["Random verse"], source: "— Kinh Pháp Cú (Dhammapada), câu 5")
    func loadRandomVerse() async -> ILHomeQuoteEntity {
        loadRandomVerseResult
    }
}
