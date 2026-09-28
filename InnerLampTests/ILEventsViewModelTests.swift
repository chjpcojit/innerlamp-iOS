//
//  ILEventsViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILEventsViewModelTests: XCTestCase {

    private var mockUseCase: MockILEventsUseCase!
    private var sut: ILEventsViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var tabSelectedSubject: PassthroughSubject<ILEventsTab, Never>!
    private var registerTappedSubject: PassthroughSubject<String, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILEventsUseCase()
        sut = ILEventsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        tabSelectedSubject = PassthroughSubject<ILEventsTab, Never>()
        registerTappedSubject = PassthroughSubject<String, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        tabSelectedSubject = nil
        registerTappedSubject = nil
        backTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILEventsViewModel.Input {
        ILEventsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            registerTapped: registerTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILEventsViewModel.Output) -> () -> ILEventsStateModel? {
        var latest: ILEventsStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILEventsNavEvent] {
        var events: [ILEventsNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - Initial state (default tab = upcoming)

    func test_initialState_mapsUpcomingTabAndFeatured() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        let state = latest()
        XCTAssertEqual(state?.selectedTab, .upcoming)
        XCTAssertEqual(state?.featured?.id, "feat")
        XCTAssertEqual(state?.featured?.seatsText, String(format: "events.hero.seatsLeft".localized, 12))
        XCTAssertEqual(state?.listTitle, "events.section.upcoming".localized)
        XCTAssertEqual(state?.items.map(\.id), ["e1", "e2"])
        // `.open` trong tab "Sắp diễn ra" → "Ghi danh".
        XCTAssertEqual(state?.items.first?.statusText, "events.status.register".localized)
        // `.closing(4)` → "Còn 4 chỗ".
        XCTAssertEqual(state?.items[1].statusText, String(format: "events.status.seatsLeft".localized, 4))
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_reloadsEventsAndMapsState() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getEventsCallCount, 2) // init + viewDidLoad
        XCTAssertEqual(latest()?.items.map(\.id), ["e1", "e2"])
    }

    // MARK: - Tab switching

    func test_tabSelected_courses_mapsCourseItems() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        tabSelectedSubject.send(.courses)

        let state = latest()
        XCTAssertEqual(state?.selectedTab, .courses)
        XCTAssertEqual(state?.listTitle, "events.section.courses".localized)
        XCTAssertEqual(state?.items.map(\.id), ["c1", "c2"])
        // `.open` trong tab "Khóa học" → "Đang mở".
        XCTAssertEqual(state?.items.first?.statusText, "events.status.open".localized)
        // `.upcoming` → "Sắp mở".
        XCTAssertEqual(state?.items[1].statusText, "events.status.upcoming".localized)
    }

    func test_tabSelected_registered_mapsRegisteredItems() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        tabSelectedSubject.send(.registered)

        let state = latest()
        XCTAssertEqual(state?.listTitle, "events.section.registered".localized)
        XCTAssertEqual(state?.items.map(\.id), ["r1"])
        XCTAssertEqual(state?.items.first?.statusText, "events.status.registered".localized)
    }

    // MARK: - Navigation

    func test_registerTapped_firesOpenRegisterEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        registerTappedSubject.send("e1")

        XCTAssertEqual(events(), [.openRegister(eventId: "e1")])
    }

    func test_registerTapped_emptyId_firesNothing() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        registerTappedSubject.send("")

        XCTAssertTrue(events().isEmpty)
    }

    func test_backTapped_firesGoBackEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.goBack])
    }
}

// MARK: - Mock ILEventsUseCase
final class MockILEventsUseCase: ILEventsUseCase {
    var events: ILEventsEntity
    private(set) var getEventsCallCount = 0

    init() {
        events = ILEventsEntity(
            featured: ILEventsFeaturedEntity(
                id: "feat",
                day: "14",
                monthLabel: "TH9",
                title: "Featured",
                meta: "Meta",
                seatsLeft: 12
            ),
            upcoming: [
                ILEventsEventEntity(
                    id: "e1",
                    name: "Name1",
                    subtitle: "Sub1",
                    day: "15",
                    monthLabel: "TH9",
                    tone: .gold,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "e2",
                    name: "Name2",
                    subtitle: "Sub2",
                    day: "22",
                    monthLabel: "TH9",
                    tone: .rose,
                    status: .closing(seatsLeft: 4)
                )
            ],
            courses: [
                ILEventsEventEntity(
                    id: "c1",
                    name: "Course1",
                    subtitle: "SubC1",
                    day: "8",
                    monthLabel: "TUẦN",
                    tone: .green,
                    status: .open
                ),
                ILEventsEventEntity(
                    id: "c2",
                    name: "Course2",
                    subtitle: "SubC2",
                    day: "4",
                    monthLabel: "TUẦN",
                    tone: .rose,
                    status: .upcoming
                )
            ],
            registered: [
                ILEventsEventEntity(
                    id: "r1",
                    name: "Reg1",
                    subtitle: "SubR1",
                    day: "14",
                    monthLabel: "TH9",
                    tone: .gold,
                    status: .registered
                )
            ]
        )
    }

    func getEvents() -> ILEventsEntity {
        getEventsCallCount += 1
        return events
    }
}
