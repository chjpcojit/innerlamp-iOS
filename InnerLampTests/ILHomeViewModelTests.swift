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

    override func setUp() {
        super.setUp()
        mockUseCase = MockILHomeUseCase()
        sut = ILHomeViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        beadTappedSubject = PassthroughSubject<Void, Never>()
        resetBeadsTappedSubject = PassthroughSubject<Void, Never>()
        malaFullscreenTappedSubject = PassthroughSubject<Void, Never>()
        lunarCalendarTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        beadTappedSubject = nil
        resetBeadsTappedSubject = nil
        malaFullscreenTappedSubject = nil
        lunarCalendarTappedSubject = nil
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
            lunarCalendarTapped: lunarCalendarTappedSubject.eraseToAnyPublisher()
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
        XCTAssertEqual(receivedState?.weekDays.count, mockUseCase.stubEntity.weekDays.count)
        XCTAssertEqual(receivedState?.eventMonths.count, mockUseCase.stubEntity.eventMonths.count)
        XCTAssertEqual(receivedState?.suggestedSessions.count, mockUseCase.stubEntity.suggestedSessions.count)
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
}

// MARK: - Mock ILHomeUseCase
final class MockILHomeUseCase: ILHomeUseCase {
    var stubEntity: ILHomeEntity = {
        var entity = ILHomeEntity()
        entity.displayName = "Tâm An"

        let today = Date()
        entity.weekDays = [
            ILHomeWeekDayEntity(id: "today", date: today, solarDay: 10, lunarDay: 16, isToday: true)
        ]
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
                title: "home.session.breathing.title".localized,
                subtitle: "home.session.breathing.subtitle".localized,
                trailingText: "home.session.breathing.trailing".localized,
                tone: .green,
                glyph: .leaf
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
}
