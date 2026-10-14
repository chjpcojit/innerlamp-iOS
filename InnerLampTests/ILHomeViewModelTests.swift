//
//  ILHomeViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILHomeViewModelTests: XCTestCase {

    private var mockUseCase: MockILHomeUseCase!
    private var mockCalendarImage: MockILCalendarImageUseCase!
    private var sut: ILHomeViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var malaFullscreenTappedSubject: PassthroughSubject<Void, Never>!
    private var lunarCalendarTappedSubject: PassthroughSubject<Void, Never>!
    private var memorialTappedSubject: PassthroughSubject<Void, Never>!
    private var lunarHeroTappedSubject: PassthroughSubject<Void, Never>!
    private var dayTappedSubject: PassthroughSubject<String, Never>!
    private var photosTappedSubject: PassthroughSubject<Void, Never>!
    private var bellTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var eventTappedSubject: PassthroughSubject<String, Never>!
    private var articleTappedSubject: PassthroughSubject<String, Never>!
    private var articlesViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var templeTappedSubject: PassthroughSubject<String, Never>!
    private var deityTappedSubject: PassthroughSubject<String, Never>!
    private var deitiesViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var suggestedSessionTappedSubject: PassthroughSubject<String, Never>!
    private var notificationTappedSubject: PassthroughSubject<Void, Never>!
    private var avatarTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILHomeUseCase()
        mockCalendarImage = MockILCalendarImageUseCase()
        mockUseCase.loadBuddhistEventMonthsResult = mockUseCase.stubEntity.eventMonths
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        malaFullscreenTappedSubject = PassthroughSubject<Void, Never>()
        lunarCalendarTappedSubject = PassthroughSubject<Void, Never>()
        memorialTappedSubject = PassthroughSubject<Void, Never>()
        lunarHeroTappedSubject = PassthroughSubject<Void, Never>()
        dayTappedSubject = PassthroughSubject<String, Never>()
        photosTappedSubject = PassthroughSubject<Void, Never>()
        bellTappedSubject = PassthroughSubject<Void, Never>()
        eventsTappedSubject = PassthroughSubject<Void, Never>()
        eventTappedSubject = PassthroughSubject<String, Never>()
        articleTappedSubject = PassthroughSubject<String, Never>()
        articlesViewAllTappedSubject = PassthroughSubject<Void, Never>()
        templeTappedSubject = PassthroughSubject<String, Never>()
        deityTappedSubject = PassthroughSubject<String, Never>()
        deitiesViewAllTappedSubject = PassthroughSubject<Void, Never>()
        suggestedSessionTappedSubject = PassthroughSubject<String, Never>()
        notificationTappedSubject = PassthroughSubject<Void, Never>()
        avatarTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        malaFullscreenTappedSubject = nil
        lunarCalendarTappedSubject = nil
        memorialTappedSubject = nil
        lunarHeroTappedSubject = nil
        dayTappedSubject = nil
        photosTappedSubject = nil
        bellTappedSubject = nil
        eventsTappedSubject = nil
        eventTappedSubject = nil
        articleTappedSubject = nil
        articlesViewAllTappedSubject = nil
        templeTappedSubject = nil
        deityTappedSubject = nil
        deitiesViewAllTappedSubject = nil
        suggestedSessionTappedSubject = nil
        notificationTappedSubject = nil
        avatarTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILHomeViewModel.Input {
        ILHomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            malaFullscreenTapped: malaFullscreenTappedSubject.eraseToAnyPublisher(),
            lunarCalendarTapped: lunarCalendarTappedSubject.eraseToAnyPublisher(),
            memorialTapped: memorialTappedSubject.eraseToAnyPublisher(),
            lunarHeroTapped: lunarHeroTappedSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            photosTapped: photosTappedSubject.eraseToAnyPublisher(),
            bellTapped: bellTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            eventTapped: eventTappedSubject.eraseToAnyPublisher(),
            articleTapped: articleTappedSubject.eraseToAnyPublisher(),
            articlesViewAllTapped: articlesViewAllTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            deitiesViewAllTapped: deitiesViewAllTappedSubject.eraseToAnyPublisher(),
            suggestedSessionTapped: suggestedSessionTappedSubject.eraseToAnyPublisher(),
            notificationTapped: notificationTappedSubject.eraseToAnyPublisher(),
            avatarTapped: avatarTappedSubject.eraseToAnyPublisher()
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

    func test_malaFullscreenTapped_firesOpenMalaNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        malaFullscreenTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openMala)
    }

    func test_memorialTapped_firesOpenMemorialNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        memorialTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openMemorial)
    }

    func test_memorialLinkText_isLocalized() {
        let output = sut.transform(input: makeInput())
        var linkText: String?
        output.state
            .prefix(1)
            .sink { state in
                if case .success(let model) = state { linkText = model.weekMemorialLinkText }
            }
            .store(in: &cancellables)

        XCTAssertEqual(linkText, "home.week.memorialLink".localized)
        XCTAssertEqual(linkText, "Sổ giỗ")
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
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
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

    func test_viewDidLoad_showsCalendarImageOfSelectedDayOnLunarHero() {
        mockCalendarImage.result = .success(ILCalendarImageEntity(
            id: "img-1", imageURL: "http://host:8080/static/images/home-calendar/img-1.jpg",
            author: "Judgefloro", license: "Public domain", licenseURL: nil, sourceURL: nil
        ))
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "calendar image applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.lunarHero.imageURL != nil {
                    XCTAssertEqual(model.lunarHero.imageURL, "http://host:8080/static/images/home-calendar/img-1.jpg")
                    XCTAssertFalse(model.lunarHero.imageCreditText.isEmpty)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockCalendarImage.requestedDates.count, 1)
    }

    func test_viewDidLoad_calendarImageFailure_keepsHeroWithoutImage() {
        mockCalendarImage.result = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        var latest: ILHomeStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertNil(latest?.lunarHero.imageURL)
        XCTAssertEqual(latest?.lunarHero.imageCreditText, "")
    }

    func test_dayTapped_requestsImageOnlyOncePerDay() {
        _ = sut.transform(input: makeInput())

        viewDidLoadSubject.send(())
        dayTappedSubject.send("day-2")
        dayTappedSubject.send("today")
        dayTappedSubject.send("day-2")

        let expectation = expectation(description: "requests settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockCalendarImage.requestedDates.count, 2)
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
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)

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

    func test_notificationTapped_firesOpenNotificationsNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        notificationTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openNotifications)
    }

    func test_avatarTapped_firesOpenProfileNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        avatarTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openProfile)
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

    func test_eventTapped_firesOpenFestivalDetailNavigationEvent() {
        let day = Date(timeIntervalSince1970: 0)
        mockUseCase.stubEntity.eventMonths = [
            ILHomeEventMonthEntity(id: "1970-01", monthLabel: "Tháng 1", events: [
                ILHomeEventItemEntity(
                    id: "vu-lan-1970-01-01", date: day, title: "Vu Lan", lunarLabel: "Rằm · Tháng Bảy",
                    tone: .gold, eventCode: "vu-lan"
                )
            ])
        ]
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILHomeNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        eventTappedSubject.send("vu-lan-1970-01-01")

        XCTAssertEqual(receivedEvent, .openFestivalDetail(code: "vu-lan", date: day))
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
        XCTAssertEqual(
            receivedState?.deities.last?.memorialText,
            "home.deity.memorialUpdating".localized,
            "No memorial day → \"updating\" line"
        )
    }

    // MARK: - Server temple / deity carousels

    func test_viewDidLoad_showsTopTemplesFromUseCase_formattedForCards() {
        mockUseCase.loadTopTemplesResult = .success([
            ILHomeTempleEntity(
                id: "temple_north_011",
                name: "Chùa Bích Động",
                address: "Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình",
                region: .north,
                heritageRank: .worldHeritage,
                establishedYear: 1428
            )
        ])
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "server temples applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.temples.first?.id == "temple_north_011" {
                    XCTAssertEqual(model.temples.count, 1)
                    XCTAssertEqual(model.temples.first?.name, "Chùa Bích Động")
                    XCTAssertEqual(model.temples.first?.place, "Ninh Bình")
                    XCTAssertEqual(model.temples.first?.region, "temple.region.north".localized)
                    XCTAssertEqual(
                        model.temples.first?.note,
                        "temple.rank.worldHeritage".localized + " · " + String(format: "home.temple.foundedFormat".localized, 1428)
                    )
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_topTemplesFailure_keepsHomeSuccessful() {
        mockUseCase.loadTopTemplesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        var states: [ViewState<ILHomeStateModel>] = []
        output.state.sink { states.append($0) }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "async loads settle")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertFalse(states.contains { if case .failure = $0 { return true } else { return false } })
    }

    func test_viewDidLoad_showsTopArticlesFromUseCase_formattedForCards() {
        mockUseCase.loadTopArticlesResult = .success([
            ILHomeArticleEntity(id: "vipassana-nghe-thuat-song", category: "Thực hành", title: "Vipassana", author: "Thầy A", readMinutes: 7),
            ILHomeArticleEntity(id: "tu-dieu-de", category: "Giáo lý", title: "Tứ Diệu Đế", author: "Thầy B", readMinutes: 3)
        ])
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "server articles applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.articles.first?.id == "vipassana-nghe-thuat-song" {
                    XCTAssertEqual(model.articles.map(\.id), ["vipassana-nghe-thuat-song", "tu-dieu-de"])
                    XCTAssertEqual(model.articles.first?.readText, String(format: "home.article.readFormat".localized, 7))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_showsTopPhotosWithThumbnailsAndMoreCount() {
        mockUseCase.loadTopPhotosResult = .success((1...10).map { ILHomePhotoEntity(id: "g\($0)", thumbnailURL: "http://h/t\($0).jpg") })
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "server photos applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.photos.first?.id == "g1" {
                    XCTAssertEqual(model.photos.count, 10)
                    XCTAssertEqual(model.photos.first?.thumbnailURL, "http://h/t1.jpg")
                    XCTAssertEqual(model.photosMoreText, String(format: "home.photos.moreFormat".localized, 7))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)
    }

    func test_viewDidLoad_topPhotosFailure_showsNoPhotosAndNoMoreOverlay() {
        mockUseCase.loadTopPhotosResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        var latest: ILHomeStateModel?
        output.state.sink { if case .success(let model) = $0 { latest = model } }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "async loads settle")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertEqual(latest?.photos, [])
        XCTAssertEqual(latest?.photosMoreText, "")
    }

    func test_viewDidLoad_topArticlesFailure_keepsHomeSuccessful() {
        mockUseCase.loadTopArticlesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        var states: [ViewState<ILHomeStateModel>] = []
        output.state.sink { states.append($0) }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "async loads settle")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertFalse(states.contains { if case .failure = $0 { return true } else { return false } })
    }

    func test_viewDidLoad_showsTopDeitiesFromUseCase() {
        mockUseCase.loadTopDeitiesResult = .success([
            ILHomeDeityEntity(id: "buddha_amitabha", kind: .buddha, name: "A Di Đà Phật", honorific: "", virtue: "", memorialDay: nil)
        ])
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "server deities applied")

        output.state
            .sink { state in
                if case .success(let model) = state, model.deities.map(\.id) == ["buddha_amitabha"] {
                    XCTAssertEqual(model.deities.first?.name, "A Di Đà Phật")
                    XCTAssertEqual(model.deities.first?.memorialText, "home.deity.memorialUpdating".localized)
                    XCTAssertEqual(model.deitiesEmptyText, "")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_topDeitiesFailure_showsUpdatingPlaceholder() {
        mockUseCase.loadTopDeitiesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "updating placeholder shown")

        output.state
            .sink { state in
                if case .success(let model) = state, !model.deitiesEmptyText.isEmpty {
                    XCTAssertTrue(model.deities.isEmpty)
                    XCTAssertEqual(model.deitiesEmptyText, "home.deity.updating".localized)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_initialState_beforeTopDeitiesLoad_hasNoPlaceholder() {
        mockUseCase.stubEntity.deities = []
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
        let output = sut.transform(input: makeInput())
        var firstState: ILHomeStateModel?
        output.state
            .prefix(1)
            .sink { state in
                if case .success(let model) = state { firstState = model }
            }
            .store(in: &cancellables)

        XCTAssertEqual(firstState?.deitiesEmptyText, "", "Still loading — no \"updating\" flash")
    }

    func test_viewDidLoad_topTemplesFailure_showsUpdatingPlaceholder() {
        mockUseCase.loadTopTemplesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "temples updating placeholder shown")

        output.state
            .sink { state in
                if case .success(let model) = state, !model.templesEmptyText.isEmpty {
                    XCTAssertTrue(model.temples.isEmpty)
                    XCTAssertEqual(model.templesEmptyText, "home.temple.updating".localized)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_topTemplesEmpty_showsUpdatingPlaceholder() {
        mockUseCase.loadTopTemplesResult = .success([])
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "temples updating placeholder shown")

        output.state
            .sink { state in
                if case .success(let model) = state, !model.templesEmptyText.isEmpty {
                    XCTAssertEqual(model.templesEmptyText, "home.temple.updating".localized)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_topArticlesFailure_showsUpdatingPlaceholder() {
        mockUseCase.loadTopArticlesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "articles updating placeholder shown")

        output.state
            .sink { state in
                if case .success(let model) = state, !model.articlesEmptyText.isEmpty {
                    XCTAssertTrue(model.articles.isEmpty)
                    XCTAssertEqual(model.articlesEmptyText, "home.article.updating".localized)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_dataPresent_hasNoPlaceholders() {
        let output = sut.transform(input: makeInput())
        var states: [ILHomeStateModel] = []
        output.state
            .sink { state in
                if case .success(let model) = state { states.append(model) }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "async loads settle")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertFalse(states.contains { !$0.temples.isEmpty && !$0.templesEmptyText.isEmpty })
        XCTAssertFalse(states.contains { !$0.articles.isEmpty && !$0.articlesEmptyText.isEmpty })
    }

    func test_initialState_beforeTemplesAndArticlesLoad_hasNoPlaceholder() {
        mockUseCase.stubEntity.temples = []
        mockUseCase.stubEntity.articles = []
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
        let output = sut.transform(input: makeInput())
        var firstState: ILHomeStateModel?
        output.state
            .prefix(1)
            .sink { state in
                if case .success(let model) = state { firstState = model }
            }
            .store(in: &cancellables)

        XCTAssertEqual(firstState?.templesEmptyText, "", "Still loading — no \"updating\" flash")
        XCTAssertEqual(firstState?.articlesEmptyText, "", "Still loading — no \"updating\" flash")
    }

    func test_initialState_beforeServerSectionsLoad_showsSkeletons() {
        mockUseCase.stubEntity.temples = []
        mockUseCase.stubEntity.deities = []
        mockUseCase.stubEntity.articles = []
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
        let output = sut.transform(input: makeInput())
        var firstState: ILHomeStateModel?
        output.state
            .prefix(1)
            .sink { state in
                if case .success(let model) = state { firstState = model }
            }
            .store(in: &cancellables)

        XCTAssertEqual(firstState?.templesLoading, true)
        XCTAssertEqual(firstState?.deitiesLoading, true)
        XCTAssertEqual(firstState?.articlesLoading, true)
    }

    func test_viewDidLoad_afterSectionsAnswer_skeletonsStop() {
        mockUseCase.loadTopTemplesResult = .failure(ILCatalogError.offline)
        mockUseCase.loadTopDeitiesResult = .success([])
        mockUseCase.loadTopArticlesResult = .failure(ILCatalogError.offline)
        let output = sut.transform(input: makeInput())
        let expectation = expectation(description: "all sections answered")

        output.state
            .sink { state in
                if case .success(let model) = state,
                   !model.templesEmptyText.isEmpty, !model.deitiesEmptyText.isEmpty, !model.articlesEmptyText.isEmpty {
                    XCTAssertFalse(model.templesLoading)
                    XCTAssertFalse(model.deitiesLoading)
                    XCTAssertFalse(model.articlesLoading)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 1)
    }

    func test_viewDidLoad_sectionWithData_neverShowsSkeleton() {
        let output = sut.transform(input: makeInput())
        var states: [ILHomeStateModel] = []
        output.state
            .sink { state in
                if case .success(let model) = state { states.append(model) }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let settled = expectation(description: "async loads settle")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 1)

        XCTAssertFalse(states.contains { !$0.temples.isEmpty && $0.templesLoading })
        XCTAssertFalse(states.contains { !$0.deities.isEmpty && $0.deitiesLoading })
        XCTAssertFalse(states.contains { !$0.articles.isEmpty && $0.articlesLoading })
    }

    func test_shortPlace_takesProvinceWithoutPrefix() {
        XCTAssertEqual(ILHomeViewModel.shortPlace(from: "Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình"), "Ninh Bình")
        XCTAssertEqual(ILHomeViewModel.shortPlace(from: "Đường Thanh Niên, Quận Tây Hồ, Hà Nội"), "Hà Nội")
        XCTAssertEqual(ILHomeViewModel.shortPlace(from: "Quận 3, TP. Hồ Chí Minh"), "TP. Hồ Chí Minh")
        XCTAssertEqual(ILHomeViewModel.shortPlace(from: ""), "")
    }

    func test_templeNote_dropsMissingParts() {
        let founded = String(format: "home.temple.foundedFormat".localized, 1049)
        XCTAssertEqual(ILHomeViewModel.templeNote(rank: .unranked, establishedYear: 1049), founded)
        XCTAssertEqual(ILHomeViewModel.templeNote(rank: .other("NEW_RANK"), establishedYear: 0), "")
        XCTAssertEqual(ILHomeViewModel.templeNote(rank: .nationalRelic, establishedYear: 0), "temple.rank.nationalRelic".localized)
    }

    func test_regionLabel_showsUnknownRegionRaw() {
        XCTAssertEqual(ILHomeViewModel.regionLabel(.central), "temple.region.central".localized)
        XCTAssertEqual(ILHomeViewModel.regionLabel(.other("highlands")), "highlands")
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
        sut = ILHomeViewModel(useCase: mockUseCase, calendarImageUseCase: mockCalendarImage)
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
                id: "temple_north_002",
                name: "Chùa Một Cột",
                address: "Phố Chùa Một Cột, Quận Ba Đình, Hà Nội",
                region: .north,
                heritageRank: .specialNationalRelic,
                establishedYear: 1049
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

    /// Defaults to the stub's temples so the async load does not change the initial state.
    lazy var loadTopTemplesResult: Result<[ILHomeTempleEntity], Error> = .success(stubEntity.temples)
    func loadTopTemples() async throws -> [ILHomeTempleEntity] {
        try loadTopTemplesResult.get()
    }

    /// Defaults to the stub's deities so the async load does not change the initial state.
    lazy var loadTopDeitiesResult: Result<[ILHomeDeityEntity], Error> = .success(stubEntity.deities)
    func loadTopDeities() async throws -> [ILHomeDeityEntity] {
        try loadTopDeitiesResult.get()
    }

    /// Defaults to the stub's articles so the async load does not change the initial state.
    lazy var loadTopPhotosResult: Result<[ILHomePhotoEntity], Error> = .success(stubEntity.photos)
    func loadTopPhotos() async throws -> [ILHomePhotoEntity] {
        try loadTopPhotosResult.get()
    }

    lazy var loadTopArticlesResult: Result<[ILHomeArticleEntity], Error> = .success(stubEntity.articles)
    func loadTopArticles() async throws -> [ILHomeArticleEntity] {
        try loadTopArticlesResult.get()
    }
}
