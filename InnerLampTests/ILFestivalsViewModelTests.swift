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
    private var hostTappedSubject: PassthroughSubject<String, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFestivalsUseCase()
        mockUseCase.loadMonthsResult = Self.stubMonths
        sut = ILFestivalsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        tabSelectedSubject = PassthroughSubject<ILFestivalsTab, Never>()
        hostTappedSubject = PassthroughSubject<String, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        tabSelectedSubject = nil
        hostTappedSubject = nil
        backTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILFestivalsViewModel.Input {
        ILFestivalsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            hostTapped: hostTappedSubject.eraseToAnyPublisher(),
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
                    id: "2026-09-15", date: stubDate, title: "Đại lễ Phật Đản", kind: .major,
                    daysUntil: 0,
                    hostTempleIDs: ["tp-tuquang", "tp-motcot", "tp-tranquoc", "tp-huong"]
                ),
                ILFestivalDayEntity(
                    id: "2026-09-16", date: stubDate, title: "Vía Văn Thù Bồ Tát", kind: .festival,
                    daysUntil: 2, hostTempleIDs: ["tp-tuquang", "tp-motcot"]
                ),
                ILFestivalDayEntity(
                    id: "2026-09-17", date: stubDate, title: "Rằm tháng Tám — ngày trai giới",
                    kind: .observance, daysUntil: 3, hostTempleIDs: ["tp-tuquang"]
                )
            ]
        )
    ]

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
        XCTAssertEqual(receivedState?.subtitle, String(format: "festivals.header.subtitleFormat".localized, 3))
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
        // 4 chùa tổ chức → 3 chip + "+1 chùa".
        XCTAssertEqual(day?.hosts.first?.name, "home.temple.tuquang.name".localized)
        XCTAssertEqual(day?.moreHostsText, String(format: "festivals.item.moreHostsFormat".localized, 1))
    }

    func test_tabSelected_festivals_filtersOutObservances() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.festivals, output: output)

        XCTAssertEqual(receivedState?.selectedTab, .festivals)
        XCTAssertEqual(receivedState?.months.first?.days.count, 2)
        XCTAssertEqual(receivedState?.months.first?.days.contains(where: { $0.title.contains("trai giới") }), false)
        XCTAssertEqual(receivedState?.subtitle, String(format: "festivals.header.subtitleFormat".localized, 2))
    }

    func test_tabSelected_observances_filtersOutFestivals() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.observances, output: output)

        XCTAssertEqual(receivedState?.selectedTab, .observances)
        XCTAssertEqual(receivedState?.months.first?.days.count, 1)
        XCTAssertEqual(receivedState?.months.first?.days.first?.isFestival, false)
        XCTAssertEqual(receivedState?.subtitle, String(format: "festivals.header.subtitleFormat".localized, 1))
    }

    func test_tabSelected_filtersOutEmptyMonth() {
        mockUseCase.loadMonthsResult = [
            ILFestivalMonthEntity(
                id: "2026-09", label: "Tháng 9, 2026",
                days: [
                    ILFestivalDayEntity(
                        id: "2026-09-17", date: Self.stubDate, title: "Rằm tháng Tám — ngày trai giới",
                        kind: .observance, daysUntil: 3, hostTempleIDs: ["tp-tuquang"]
                    )
                ]
            )
        ]
        sut = ILFestivalsViewModel(useCase: mockUseCase)

        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        let receivedState = applyTab(.festivals, output: output)

        XCTAssertEqual(receivedState?.months.isEmpty, true)
        XCTAssertEqual(receivedState?.subtitle, String(format: "festivals.header.subtitleFormat".localized, 0))
    }

    func test_hostTapped_firesOpenTempleNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILFestivalsNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        hostTappedSubject.send("tp-motcot")

        XCTAssertEqual(receivedEvent, .openTemple(id: "tp-motcot"))
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

    func loadMonths(from date: Date) async throws -> [ILFestivalMonthEntity] {
        loadMonthsCalled = true
        if let error = loadMonthsError { throw error }
        return loadMonthsResult
    }
}
