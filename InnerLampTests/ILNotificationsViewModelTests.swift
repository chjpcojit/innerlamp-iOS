//
//  ILNotificationsViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILNotificationsViewModelTests: XCTestCase {

    private var mockUseCase: MockILNotificationsUseCase!
    private var sut: ILNotificationsViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var closeTappedSubject: PassthroughSubject<Void, Never>!
    private var sitNowTappedSubject: PassthroughSubject<Void, Never>!
    private var skipTonightTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILNotificationsUseCase()
        sut = ILNotificationsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        closeTappedSubject = PassthroughSubject<Void, Never>()
        sitNowTappedSubject = PassthroughSubject<Void, Never>()
        skipTonightTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        closeTappedSubject = nil
        sitNowTappedSubject = nil
        skipTonightTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILNotificationsViewModel.Input {
        ILNotificationsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher(),
            sitNowTapped: sitNowTappedSubject.eraseToAnyPublisher(),
            skipTonightTapped: skipTonightTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILNotificationsViewModel.Output) -> () -> ILNotificationsStateModel? {
        var latest: ILNotificationsStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILNotificationsNavEvent] {
        var events: [ILNotificationsNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_mapsEntitiesToStateModel() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getUpcomingCallCount, 2) // init + viewDidLoad
        XCTAssertGreaterThanOrEqual(mockUseCase.getNotificationsCallCount, 2) // init + viewDidLoad

        let state = latest()
        XCTAssertEqual(state?.hero?.eyebrow, "SẮP DIỄN RA · 30 PHÚT NỮA")
        XCTAssertEqual(state?.hero?.title, "Thời khóa tối cùng đạo tràng")

        XCTAssertEqual(state?.items.count, 2)
        XCTAssertEqual(state?.items[0].id, "n1")
        XCTAssertEqual(state?.items[0].kind, .bell)
        XCTAssertEqual(state?.items[0].title, "Chuông tỉnh thức")
        XCTAssertEqual(state?.items[0].body, "Body 1")
        XCTAssertEqual(state?.items[0].isRead, false)
        XCTAssertFalse(state?.items[0].relativeTime.isEmpty ?? true)

        XCTAssertEqual(state?.items[1].kind, .sangha)
        XCTAssertEqual(state?.items[1].isRead, true)
    }

    func test_viewDidLoad_withNoUpcoming_hidesHero() {
        mockUseCase.upcoming = nil
        sut = ILNotificationsViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.hero)
    }

    // MARK: - skipTonight
    func test_skipTonightTapped_dismissesHero() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        skipTonightTappedSubject.send(())

        XCTAssertNil(latest()?.hero)
    }

    // MARK: - Navigation
    func test_closeTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        closeTappedSubject.send(())

        XCTAssertEqual(events(), [.goBack])
    }

    func test_sitNowTapped_firesOpenSetup() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        sitNowTappedSubject.send(())

        XCTAssertEqual(events(), [.openSetup])
    }

    // MARK: - Formatting helpers
    func test_formatRelativeTime_bucketsByThreshold() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(-30), now: now),
            "notifications.time.justNow".localized
        )
        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(-5 * 60), now: now),
            String(format: "notifications.time.minutesAgo".localized, 5)
        )
        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(-2 * 3_600), now: now),
            String(format: "notifications.time.hoursAgo".localized, 2)
        )
        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(-86_400), now: now),
            "notifications.time.yesterday".localized
        )
        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(-3 * 86_400), now: now),
            String(format: "notifications.time.daysAgo".localized, 3)
        )
    }

    func test_formatRelativeTime_clampsFutureDatesToJustNow() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(
            ILNotificationsViewModel.formatRelativeTime(now.addingTimeInterval(5_000), now: now),
            "notifications.time.justNow".localized
        )
    }
}

// MARK: - Mock ILNotificationsUseCase
final class MockILNotificationsUseCase: ILNotificationsUseCase {
    var upcoming: ILNotificationUpcomingEntity?
    var notifications: [ILNotificationEntity]
    private(set) var getUpcomingCallCount = 0
    private(set) var getNotificationsCallCount = 0

    init() {
        upcoming = ILNotificationUpcomingEntity(
            eyebrow: "SẮP DIỄN RA · 30 PHÚT NỮA",
            title: "Thời khóa tối cùng đạo tràng"
        )
        notifications = [
            ILNotificationEntity(
                id: "n1", kind: .bell, title: "Chuông tỉnh thức", body: "Body 1",
                timestamp: Date(), isRead: false
            ),
            ILNotificationEntity(
                id: "n2", kind: .sangha, title: "Đạo tràng Từ Quang", body: "Body 2",
                timestamp: Date(), isRead: true
            )
        ]
    }

    func getUpcoming() -> ILNotificationUpcomingEntity? {
        getUpcomingCallCount += 1
        return upcoming
    }

    func getNotifications() -> [ILNotificationEntity] {
        getNotificationsCallCount += 1
        return notifications
    }
}
