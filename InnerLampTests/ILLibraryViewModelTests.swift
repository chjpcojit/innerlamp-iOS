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
    private var categorySelectedSubject: PassthroughSubject<ILLibraryCategory, Never>!
    private var searchTappedSubject: PassthroughSubject<Void, Never>!
    private var featuredTappedSubject: PassthroughSubject<Void, Never>!
    private var itemTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLibraryUseCase()
        sut = ILLibraryViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        categorySelectedSubject = PassthroughSubject<ILLibraryCategory, Never>()
        searchTappedSubject = PassthroughSubject<Void, Never>()
        featuredTappedSubject = PassthroughSubject<Void, Never>()
        itemTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        categorySelectedSubject = nil
        searchTappedSubject = nil
        featuredTappedSubject = nil
        itemTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILLibraryViewModel.Input {
        ILLibraryViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            searchTapped: searchTappedSubject.eraseToAnyPublisher(),
            featuredTapped: featuredTappedSubject.eraseToAnyPublisher(),
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
    func test_viewDidLoad_selectsAllChipAndShowsWholeCatalog() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getCatalogCallCount, 2) // init + viewDidLoad
        let state = latest()
        XCTAssertEqual(state?.chips.map(\.category), ILLibraryCategory.allCases)
        XCTAssertEqual(state?.chips.filter(\.isSelected).map(\.category), [.all])
        XCTAssertEqual(state?.rows.map(\.id), ["s1", "m1", "t1"])
        XCTAssertEqual(state?.featured?.id, "featured")
    }

    // MARK: - categorySelected
    func test_categorySelected_filtersRowsSelectsChipAndKeepsFeatured() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        categorySelectedSubject.send(.meditation)

        XCTAssertEqual(mockUseCase.lastFilterCategory, .meditation)
        let state = latest()
        XCTAssertEqual(state?.rows.map(\.id), ["m1"])
        XCTAssertEqual(state?.chips.filter(\.isSelected).map(\.category), [.meditation])
        XCTAssertEqual(state?.sectionTitle, "library.section.meditation".localized)
        XCTAssertEqual(state?.featured?.id, "featured")
    }

    func test_categorySelected_sameCategory_doesNotEmitNewState() {
        let output = sut.transform(input: makeInput())
        var emissionCount = 0
        output.state
            .sink { _ in emissionCount += 1 }
            .store(in: &cancellables)
        let baseline = emissionCount

        categorySelectedSubject.send(.all)

        XCTAssertEqual(emissionCount, baseline)
    }

    func test_categorySelected_withNoMatches_marksListEmpty() {
        mockUseCase.catalog.items = mockUseCase.catalog.items.filter { $0.kind != .talk }
        sut = ILLibraryViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        categorySelectedSubject.send(.talk)

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

        itemTappedSubject.send("m1")

        XCTAssertEqual(receivedEvent, .openItem(id: "m1", kind: .meditation))
    }

    func test_itemTapped_unknownId_firesNothing() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLibraryNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        itemTappedSubject.send("does-not-exist")

        XCTAssertNil(receivedEvent)
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

// MARK: - ILLibraryUseCaseImpl (real filter logic)
final class ILLibraryUseCaseTests: XCTestCase {

    private let sut = ILLibraryUseCaseImpl()

    func test_items_all_returnsEveryItemInOriginalOrder() {
        let catalog = sut.getCatalog()
        XCTAssertEqual(sut.items(in: catalog, category: .all), catalog.items)
    }

    func test_items_byCategory_returnsOnlyMatchingKind() {
        let catalog = sut.getCatalog()
        for category in ILLibraryCategory.allCases where category != .all {
            let result = sut.items(in: catalog, category: category)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.allSatisfy { $0.kind == category.kind })
        }
    }
}

// MARK: - Mock ILLibraryUseCase
final class MockILLibraryUseCase: ILLibraryUseCase {
    var catalog = ILLibraryEntity(
        featured: ILLibraryFeaturedEntity(id: "featured", eyebrow: "eyebrow", title: "title", durationMinutes: 46),
        items: [
            ILLibraryItemEntity(id: "s1", kind: .sutra, title: "Sutra", subtitle: "sub", durationMinutes: 130, tone: .gold),
            ILLibraryItemEntity(id: "m1", kind: .meditation, title: "Meditation", subtitle: "sub", durationMinutes: 10, tone: .green),
            ILLibraryItemEntity(id: "t1", kind: .talk, title: "Talk", subtitle: "sub", durationMinutes: 62, tone: .rose)
        ]
    )
    var getCatalogCallCount = 0
    var lastFilterCategory: ILLibraryCategory?

    func getCatalog() -> ILLibraryEntity {
        getCatalogCallCount += 1
        return catalog
    }

    func items(in catalog: ILLibraryEntity, category: ILLibraryCategory) -> [ILLibraryItemEntity] {
        lastFilterCategory = category
        guard let kind = category.kind else { return catalog.items }
        return catalog.items.filter { $0.kind == kind }
    }
}
