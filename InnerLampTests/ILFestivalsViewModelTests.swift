//
//  ILFestivalsViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILFestivalsViewModelTests: XCTestCase {

    private var mockUseCase: MockILFestivalsUseCase!
    private var sut: ILFestivalsViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var tabSelectedSubject: PassthroughSubject<ILFestivalsTab, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var loadMoreSubject: PassthroughSubject<Void, Never>!
    private var dayTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFestivalsUseCase()
        mockUseCase.loadMonthsResult = Self.stubMonths
        sut = ILFestivalsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        tabSelectedSubject = PassthroughSubject<ILFestivalsTab, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        loadMoreSubject = PassthroughSubject<Void, Never>()
        dayTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        tabSelectedSubject = nil
        backTappedSubject = nil
        loadMoreSubject = nil
        dayTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILFestivalsViewModel.Input {
        ILFestivalsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    // MARK: - Stub data

    private static let stubDate = Date(timeIntervalSince1970: 0)

    private static let stubMonths: [ILFestivalMonthEntity] = [
        ILFestivalMonthEntity(
            id: "2026-09",
            label: "Tháng 9, 2026",
            days: [
                ILFestivalDayEntity(
                    id: "2026-09-15", date: stubDate, title: "Đại lễ Phật Đản", kind: .festival,
                    daysUntil: 0,
                    lunarDay: 15, lunarMonth: 8, isLeapMonth: false,
                    eventCode: "phat-dan"
                ),
                ILFestivalDayEntity(
                    id: "2026-09-16", date: stubDate, title: "Vía Văn Thù Bồ Tát", kind: .festival,
                    daysUntil: 2,
                    lunarDay: 15, lunarMonth: 8, isLeapMonth: false
                ),
                ILFestivalDayEntity(
                    id: "2026-09-17", date: stubDate, title: "Rằm tháng Tám — ngày trai giới",
                    kind: .observance, daysUntil: 3,
                    lunarDay: 15, lunarMonth: 8, isLeapMonth: false
                )
            ]
        )
    ]

    private static var currentYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: Date())
    }

    private static func subtitle(total: Int) -> String {
        String(format: "festivals.header.subtitleFormat".localized, "\(currentYear)", total)
    }

    // MARK: - Tests

    func test_viewDidLoad_loadsMonthsAndEmitsSuccess() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILFestivalsStateModel?
        let successExpectation = expectation(description: "state becomes success")
        output.state
            .sink { state in
                if case .success(let model) = state {
                    receivedState = model
                    successExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [successExpectation], timeout: 1.0)

        XCTAssertTrue(mockUseCase.loadMonthsCalled)
        XCTAssertEqual(receivedState?.selectedTab, .all)
        XCTAssertEqual(receivedState?.months.count, 1)
        XCTAssertEqual(receivedState?.months.first?.days.count, 3)
        XCTAssertEqual(receivedState?.subtitle, Self.subtitle(total: 3))
    }

    func test_viewDidLoad_mapsFestivalDayFields() {
        let output = sut.transform(input: makeInput())

        var receivedState: ILFestivalsStateModel?
        let successExpectation = expectation(description: "state becomes success")
        output.state
            .sink { state in
                if case .success(let model) = state {
                    receivedState = model
                    successExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [successExpectation], timeout: 1.0)

        let day = receivedState?.months.first?.days.first
        XCTAssertEqual(day?.title, "Đại lễ Phật Đản")
        XCTAssertEqual(day?.isFestival, true)
        XCTAssertEqual(day?.isToday, true)
        XCTAssertEqual(day?.countdownText, "festivals.item.countdown.today".localized)
        XCTAssertFalse(day?.lunarSubtitle.isEmpty ?? true)
    }

    func test_tabSelected_festivals_filtersOutObservances() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.festivals, output: output)

        XCTAssertEqual(receivedState?.selectedTab, .festivals)
        XCTAssertEqual(receivedState?.months.first?.days.count, 2)
        XCTAssertEqual(receivedState?.months.first?.days.contains(where: { $0.title.contains("trai giới") }), false)
        XCTAssertEqual(receivedState?.subtitle, Self.subtitle(total: 2))
    }

    func test_tabSelected_observances_filtersOutFestivals() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.observances, output: output)

        XCTAssertEqual(receivedState?.selectedTab, .observances)
        XCTAssertEqual(receivedState?.months.first?.days.count, 1)
        XCTAssertEqual(receivedState?.months.first?.days.first?.isFestival, false)
        XCTAssertEqual(receivedState?.subtitle, Self.subtitle(total: 1))
    }

    func test_tabSelected_filtersOutEmptyMonth() {
        mockUseCase.loadMonthsResult = [
            ILFestivalMonthEntity(
                id: "2026-09", label: "Tháng 9, 2026",
                days: [
                    ILFestivalDayEntity(
                        id: "2026-09-17", date: Self.stubDate, title: "Rằm tháng Tám — ngày trai giới",
                        kind: .observance, daysUntil: 3,
                        lunarDay: 15, lunarMonth: 8, isLeapMonth: false
                    )
                ]
            )
        ]
        sut = ILFestivalsViewModel(useCase: mockUseCase)

        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.festivals, output: output)

        XCTAssertEqual(receivedState?.months.isEmpty, true)
        XCTAssertEqual(receivedState?.subtitle, Self.subtitle(total: 0))
    }

    func test_viewDidLoad_requestsCurrentYear() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        XCTAssertEqual(mockUseCase.requestedYears, [Self.currentYear])
    }

    func test_loadMore_loadsNextYearAndAppendsMonths() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)
        mockUseCase.loadMonthsResult = [
            ILFestivalMonthEntity(
                id: "next-01", label: "Tháng 1",
                days: [
                    ILFestivalDayEntity(
                        id: "next-01-01", date: Self.stubDate, title: "Rằm", kind: .observance, daysUntil: 100,
                        lunarDay: 15, lunarMonth: 8, isLeapMonth: false
                    )
                ]
            )
        ]

        var received: ILFestivalsStateModel?
        let appended = expectation(description: "next year appended")
        output.state
            .sink { state in
                if case .success(let model) = state, model.months.count == 2 {
                    received = model
                    appended.fulfill()
                }
            }
            .store(in: &cancellables)

        loadMoreSubject.send(())
        wait(for: [appended], timeout: 1.0)

        XCTAssertEqual(mockUseCase.requestedYears, [Self.currentYear, Self.currentYear + 1])
        XCTAssertEqual(received?.months.map(\.id), ["2026-09", "next-01"])
        XCTAssertEqual(
            received?.subtitle,
            String(format: "festivals.header.subtitleFormat".localized, "\(Self.currentYear)–\(Self.currentYear + 1)", 4)
        )
    }

    func test_loadMore_failure_keepsExistingMonths() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)
        mockUseCase.loadMonthsError = NSError(domain: "test", code: 1)

        var failureCount = 0
        output.state
            .sink { state in
                if case .failure = state { failureCount += 1 }
            }
            .store(in: &cancellables)

        loadMoreSubject.send(())
        let settled = expectation(description: "load more settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
        wait(for: [settled], timeout: 1.0)

        XCTAssertEqual(failureCount, 0)
        XCTAssertEqual(mockUseCase.requestedYears.count, 2)
    }

    func test_backTapped_firesGoBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILFestivalsNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_dayTapped_festival_firesOpenFestivalDetailNavigationEvent() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)
        var receivedEvent: ILFestivalsNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        dayTappedSubject.send("2026-09-15")

        XCTAssertEqual(receivedEvent, .openFestivalDetail(code: "phat-dan", date: Self.stubDate))
    }

    func test_dayTapped_observance_doesNotNavigate() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)
        var receivedEvent: ILFestivalsNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        dayTappedSubject.send("2026-09-17")

        XCTAssertNil(receivedEvent)
    }

    func test_viewDidLoad_failure_emitsFailure() {
        mockUseCase.loadMonthsError = NSError(domain: "test", code: 1)
        sut = ILFestivalsViewModel(useCase: mockUseCase)

        let output = sut.transform(input: makeInput())

        var receivedFailure: Error?
        let failureExpectation = expectation(description: "state becomes failure")
        output.state
            .sink { state in
                if case .failure(let error) = state {
                    receivedFailure = error
                    failureExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [failureExpectation], timeout: 1.0)

        XCTAssertNotNil(receivedFailure)
    }

    // MARK: - Helpers

    /// Chạy viewDidLoad và đợi state sang `.success` — trả về model nhận được (để test tab lọc).
    @discardableResult
    private func waitForSuccess(_ output: ILFestivalsViewModel.Output) -> ILFestivalsStateModel? {
        var received: ILFestivalsStateModel?
        let successExpectation = expectation(description: "state becomes success")
        output.state
            .sink { state in
                if case .success(let model) = state {
                    received = model
                    successExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [successExpectation], timeout: 1.0)
        return received
    }

    /// Chạm 1 tab lọc sau khi đã load xong — chờ state mang `selectedTab == tab` tới rồi trả về.
    @discardableResult
    private func applyTab(_ tab: ILFestivalsTab, output: ILFestivalsViewModel.Output) -> ILFestivalsStateModel? {
        var received: ILFestivalsStateModel?
        let applied = expectation(description: "tab \(tab.rawValue) applied")
        output.state
            .sink { state in
                if case .success(let model) = state, model.selectedTab == tab {
                    received = model
                    applied.fulfill()
                }
            }
            .store(in: &cancellables)

        tabSelectedSubject.send(tab)
        wait(for: [applied], timeout: 1.0)
        return received
    }
}

// MARK: - Mock ILFestivalsUseCase
final class MockILFestivalsUseCase: ILFestivalsUseCase {
    var loadMonthsCalled = false
    var loadMonthsResult: [ILFestivalMonthEntity] = []
    var loadMonthsError: Error?

    var requestedYears: [Int] = []

    func loadMonths(year: Int, today date: Date) async throws -> [ILFestivalMonthEntity] {
        loadMonthsCalled = true
        requestedYears.append(year)
        if let error = loadMonthsError { throw error }
        return loadMonthsResult
    }
}
