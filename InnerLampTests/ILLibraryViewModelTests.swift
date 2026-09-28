//
//  ILLibraryViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLibraryViewModelTests: XCTestCase {

    private var mockUseCase: MockILLibraryUseCase!
    private var sut: ILLibraryViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var quickAccessTappedSubject: PassthroughSubject<ILLibraryQuickAccessKind, Never>!
    private var searchTappedSubject: PassthroughSubject<Void, Never>!
    private var featuredTappedSubject: PassthroughSubject<Void, Never>!
    private var deityTappedSubject: PassthroughSubject<String, Never>!
    private var deitiesViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var sutrasViewAllTappedSubject: PassthroughSubject<Void, Never>!
    private var itemTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLibraryUseCase()
        sut = ILLibraryViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        quickAccessTappedSubject = PassthroughSubject<ILLibraryQuickAccessKind, Never>()
        searchTappedSubject = PassthroughSubject<Void, Never>()
        featuredTappedSubject = PassthroughSubject<Void, Never>()
        deityTappedSubject = PassthroughSubject<String, Never>()
        deitiesViewAllTappedSubject = PassthroughSubject<Void, Never>()
        sutrasViewAllTappedSubject = PassthroughSubject<Void, Never>()
        itemTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        quickAccessTappedSubject = nil
        searchTappedSubject = nil
        featuredTappedSubject = nil
        deityTappedSubject = nil
        deitiesViewAllTappedSubject = nil
        sutrasViewAllTappedSubject = nil
        itemTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILLibraryViewModel.Input {
        ILLibraryViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            quickAccessTapped: quickAccessTappedSubject.eraseToAnyPublisher(),
            searchTapped: searchTappedSubject.eraseToAnyPublisher(),
            featuredTapped: featuredTappedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            deitiesViewAllTapped: deitiesViewAllTappedSubject.eraseToAnyPublisher(),
            sutrasViewAllTapped: sutrasViewAllTappedSubject.eraseToAnyPublisher(),
            itemTapped: itemTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILLibraryViewModel.Output) -> () -> ILLibraryStateModel? {
        var latest: ILLibraryStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_showsQuickAccessDeitiesAndRows() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getCatalogCallCount, 2) // init + viewDidLoad
        let state = latest()
        XCTAssertEqual(state?.quickAccess.map(\.kind), [.sutras, .meditation, .talk, .buddhas])
        XCTAssertEqual(state?.rows.map(\.id), ["s1"])
        XCTAssertEqual(state?.featured?.id, "featured")
        XCTAssertEqual(state?.deities.map(\.id), ["d1"])
        XCTAssertEqual(state?.sutrasSectionTitle, "library.section.sutra".localized)
        XCTAssertEqual(state?.sutrasViewAllText, "library.section.sutra.viewAll".localized)
    }

    func test_emptyRows_marksListEmpty() {
        mockUseCase.catalog.items = []
        sut = ILLibraryViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.isListEmpty, true)
    }

    // MARK: - Navigation
    func test_searchTapped_firesOpenSearchEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        searchTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openSearch)
    }

    func test_featuredTapped_firesOpenItemEventForTalk() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        featuredTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openItem(id: "featured", kind: .talk))
    }

    func test_itemTapped_firesOpenItemEventWithItemKind() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        itemTappedSubject.send("s1")

        XCTAssertEqual(receivedEvent, .openItem(id: "s1", kind: .sutra))
    }

    func test_itemTapped_unknownId_firesNothing() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        itemTappedSubject.send("does-not-exist")

        XCTAssertNil(receivedEvent)
    }

    func test_quickAccessTapped_firesOpenQuickAccessEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        quickAccessTappedSubject.send(.meditation)

        XCTAssertEqual(receivedEvent, .openQuickAccess(.meditation))
    }

    func test_deityTapped_firesOpenDeityEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        deityTappedSubject.send("d1")

        XCTAssertEqual(receivedEvent, .openDeity(id: "d1"))
    }

    func test_deitiesViewAllTapped_firesOpenDeitiesEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        deitiesViewAllTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openDeities)
    }

    func test_sutrasViewAllTapped_firesOpenQuickAccessSutrasEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        sutrasViewAllTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openQuickAccess(.sutras))
    }

    // MARK: - Duration formatting
    func test_formatDuration_underAnHour_usesMinutes() {
        XCTAssertEqual(ILLibraryViewModel.formatDuration(minutes: 38), String(format: "library.duration.minutes".localized, 38))
    }

    func test_formatDuration_overAnHour_usesHoursAndMinutes() {
        XCTAssertEqual(ILLibraryViewModel.formatDuration(minutes: 130), String(format: "library.duration.hoursMinutes".localized, 2, 10))
    }

    func test_formatDuration_wholeHours_omitsMinutes() {
        XCTAssertEqual(ILLibraryViewModel.formatDuration(minutes: 120), String(format: "library.duration.hours".localized, 2))
    }
}

// MARK: - ILLibraryUseCaseImpl (real deity mapping)
final class ILLibraryUseCaseTests: XCTestCase {

    private let sut = ILLibraryUseCaseImpl(deityUseCase: MockILDeityUseCase())

    func test_getCatalog_mapsDeitiesFromDeityUseCase() {
        let catalog = sut.getCatalog()
        XCTAssertFalse(catalog.deities.isEmpty)
        XCTAssertFalse(catalog.items.isEmpty)
        XCTAssertTrue(catalog.items.allSatisfy { $0.kind == .sutra })
    }
}

// MARK: - Mock ILLibraryUseCase
final class MockILLibraryUseCase: ILLibraryUseCase {
    var catalog = ILLibraryEntity(
        featured: ILLibraryFeaturedEntity(id: "featured", eyebrow: "eyebrow", title: "title", durationMinutes: 46),
        items: [
            ILLibraryItemEntity(id: "s1", kind: .sutra, title: "Sutra", subtitle: "sub", durationMinutes: 130, tone: .gold)
        ],
        deities: [
            ILHomeDeityEntity(id: "d1", kind: .buddha, name: "Thích Ca", honorific: "honorific", virtue: "virtue", memorialDay: nil)
        ]
    )
    var getCatalogCallCount = 0

    func getCatalog() -> ILLibraryEntity {
        getCatalogCallCount += 1
        return catalog
    }
}
