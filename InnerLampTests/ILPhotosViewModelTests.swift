//
//  ILPhotosViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILPhotosViewModelTests: XCTestCase {

    private var mockUseCase: MockILPhotosUseCase!
    private var sut: ILPhotosViewModel!
    private var output: ILPhotosViewModel.Output!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var categorySelectedSubject: PassthroughSubject<ILPhotosCategory?, Never>!
    private var loadMoreTriggeredSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var photoSelectedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILPhotosUseCase()
        sut = ILPhotosViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        categorySelectedSubject = PassthroughSubject<ILPhotosCategory?, Never>()
        loadMoreTriggeredSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        photoSelectedSubject = PassthroughSubject<String, Never>()

        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: ILPhotosViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            photoSelected: photoSelectedSubject.eraseToAnyPublisher()
        ))
    }

    override func tearDown() {
        cancellables = nil
        photoSelectedSubject = nil
        backTappedSubject = nil
        loadMoreTriggeredSubject = nil
        categorySelectedSubject = nil
        viewDidLoadSubject = nil
        output = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    /// Fulfilled the first time a `.success` model satisfying `predicate` is emitted. `predicate`
    /// runs for every emission, so it can also record the latest model for the assertions.
    private func waitForState(_ predicate: @escaping (ILPhotosStateModel) -> Bool) -> XCTestExpectation {
        let expectation = expectation(description: "state matching predicate")
        var fulfilled = false
        output.state
            .sink { state in
                guard case .success(let model) = state else { return }
                if predicate(model), !fulfilled {
                    fulfilled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        return expectation
    }

    func test_init_startsEmptyWithoutLoading() {
        var latest: ILPhotosStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)

        XCTAssertEqual(latest?.photos, [])
        XCTAssertEqual(mockUseCase.firstPageCategories.count, 0)
    }

    func test_viewDidLoad_loadsAllCategoriesAndShowsServerTotalInSubtitle() {
        var latest: ILPhotosStateModel?
        let loaded = waitForState { latest = $0; return !$0.photos.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertEqual(mockUseCase.firstPageCategories, [nil])
        XCTAssertEqual(latest?.photos.map(\.id), ["g-1", "g-2"])
        XCTAssertEqual(latest?.photos.first?.thumbnailURL, "http://host/thumb/g-1.jpg")
        // Chip lọc: "Tất cả" + 4 danh mục, "Tất cả" đang chọn.
        XCTAssertEqual(latest?.categories.count, 5)
        XCTAssertEqual(latest?.categories.first?.isSelected, true)
        XCTAssertEqual(latest?.subtitle, String(format: "photos.subtitle.count".localized, 86))
        XCTAssertEqual(latest?.hasMore, true)
        XCTAssertEqual(latest?.isLoadingMore, false)
    }

    func test_viewDidLoad_showsLoadingFooterWhileFirstPageIsInFlight() {
        var sawLoading = false
        let loaded = waitForState { if $0.isLoadingMore { sawLoading = true }; return !$0.photos.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertTrue(sawLoading)
    }

    func test_viewDidLoad_failure_clearsSpinnerThenEmitsFailure() {
        mockUseCase.firstPageError = ILCatalogError.offline
        var order: [String] = []
        output.state
            .sink { state in
                switch state {
                case .success(let model): order.append(model.isLoadingMore ? "loading" : "idle")
                case .failure: order.append("failure")
                default: break
                }
            }
            .store(in: &cancellables)
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { if case .failure = $0 { failed.fulfill() } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 2)

        XCTAssertEqual(Array(order.suffix(3)), ["loading", "idle", "failure"])
    }

    func test_categorySelected_temple_reloadsFirstPageForThatCategory() {
        var latest: ILPhotosStateModel?
        let loaded = waitForState { latest = $0; return $0.categories.first { $0.isSelected }?.category == .temple && !$0.photos.isEmpty }

        categorySelectedSubject.send(.temple)
        wait(for: [loaded], timeout: 2)

        XCTAssertEqual(mockUseCase.firstPageCategories, [.temple])
        XCTAssertEqual(
            latest?.subtitle,
            String(format: "photos.subtitle.countCategory".localized, 86, "photos.category.temple".localized)
        )
    }

    func test_categorySelected_sameCategoryAgain_doesNotReloadWhenPhotosAreShown() {
        let loaded = waitForState { !$0.photos.isEmpty }
        categorySelectedSubject.send(.festival)
        wait(for: [loaded], timeout: 2)

        categorySelectedSubject.send(.festival)

        XCTAssertEqual(mockUseCase.firstPageCategories, [.festival])
    }

    func test_categorySelected_keepsCurrentPhotosUntilNewPageArrives() {
        let firstLoaded = waitForState { !$0.photos.isEmpty }
        viewDidLoadSubject.send(())
        wait(for: [firstLoaded], timeout: 2)
        mockUseCase.firstPageDelays = [.festival: 300_000_000]
        var duringSwitch: ILPhotosStateModel?
        let switching = waitForState { state in
            if state.isLoadingMore, state.categories.first(where: { $0.isSelected })?.category == .festival {
                duringSwitch = state
                return true
            }
            return false
        }

        categorySelectedSubject.send(.festival)
        wait(for: [switching], timeout: 2)

        // The chip moves at once but the old photos stay, so the grid can crossfade to the new ones.
        XCTAssertEqual(duringSwitch?.photos.map(\.id), ["g-1", "g-2"])
        XCTAssertEqual(duringSwitch?.subtitle, String(format: "photos.subtitle.count".localized, 86))
    }

    func test_categorySelected_failure_movesChipBackAndKeepsPhotos() {
        var latest: ILPhotosStateModel?
        let firstLoaded = waitForState { latest = $0; return !$0.photos.isEmpty }
        viewDidLoadSubject.send(())
        wait(for: [firstLoaded], timeout: 2)
        mockUseCase.firstPageError = ILCatalogError.offline
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { if case .failure = $0 { failed.fulfill() } }
            .store(in: &cancellables)

        categorySelectedSubject.send(.festival)
        wait(for: [failed], timeout: 2)

        XCTAssertEqual(latest?.categories.first(where: { $0.isSelected })?.category, nil)
        XCTAssertEqual(latest?.photos.count, 2)
        XCTAssertEqual(latest?.isLoadingMore, false)
    }

    func test_categorySelected_staleResponseIsDiscarded() {
        // The first request (temple) is slow; the second (festival) answers first.
        mockUseCase.firstPageDelays = [.temple: 300_000_000]
        var latest: ILPhotosStateModel?
        let settled = waitForState { latest = $0; return false }
        settled.isInverted = true

        categorySelectedSubject.send(.temple)
        categorySelectedSubject.send(.festival)
        wait(for: [settled], timeout: 0.8)

        XCTAssertEqual(latest?.categories.first { $0.isSelected }?.category, .festival)
        XCTAssertEqual(latest?.photos.map(\.id), ["g-1", "g-2"])
        XCTAssertEqual(mockUseCase.firstPageCategories, [.temple, .festival])
    }

    func test_loadMore_appendsNextPage() {
        var latest: ILPhotosStateModel?
        let firstLoaded = waitForState { !$0.photos.isEmpty }
        viewDidLoadSubject.send(())
        wait(for: [firstLoaded], timeout: 2)
        let appended = waitForState { latest = $0; return $0.photos.count == 4 }

        loadMoreTriggeredSubject.send(())
        wait(for: [appended], timeout: 2)

        XCTAssertEqual(mockUseCase.nextPageCallCount, 1)
        XCTAssertEqual(latest?.photos.map(\.id), ["g-1", "g-2", "g-3", "g-4"])
        XCTAssertEqual(latest?.hasMore, false)
    }

    func test_loadMore_whenNoMorePages_doesNotCallUseCase() {
        mockUseCase.hasMoreAfterFirstPage = false
        let firstLoaded = waitForState { !$0.photos.isEmpty }
        viewDidLoadSubject.send(())
        wait(for: [firstLoaded], timeout: 2)

        loadMoreTriggeredSubject.send(())

        XCTAssertEqual(mockUseCase.nextPageCallCount, 0)
    }

    func test_loadMore_failure_keepsLoadedPhotosAndAllowsRetry() {
        var latest: ILPhotosStateModel?
        let firstLoaded = waitForState { latest = $0; return !$0.photos.isEmpty }
        viewDidLoadSubject.send(())
        wait(for: [firstLoaded], timeout: 2)
        mockUseCase.nextPageError = ILCatalogError.offline
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { if case .failure = $0 { failed.fulfill() } }
            .store(in: &cancellables)

        loadMoreTriggeredSubject.send(())
        wait(for: [failed], timeout: 2)

        XCTAssertEqual(latest?.photos.count, 2)
        XCTAssertEqual(latest?.isLoadingMore, false)
        XCTAssertEqual(latest?.hasMore, true)
    }

    func test_backTapped_firesBackNavigationEvent() {
        var receivedEvent: ILPhotosNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_photoSelected_firesOpenPhotoWithLoadedList() {
        var loadedPhotos: [ILPhotosPhotoModel] = []
        let loaded = waitForState { model in
            loadedPhotos = model.photos
            return model.photos.count == 2
        }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        var receivedEvent: ILPhotosNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        photoSelectedSubject.send("g-2")

        XCTAssertEqual(receivedEvent, .openPhoto(photos: loadedPhotos, selectedID: "g-2"))
        XCTAssertEqual(loadedPhotos.first?.imageURL, "http://host/full/g-1.jpg")
    }

    func test_photoSelected_unknownID_isIgnored() {
        var receivedEvent: ILPhotosNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        photoSelectedSubject.send("missing")

        XCTAssertNil(receivedEvent)
    }
}

// MARK: - Mock ILPhotosUseCase
/// First page = `g-1`, `g-2` of an 86-photo catalog; the next page adds `g-3`, `g-4` and ends it.
final class MockILPhotosUseCase: ILPhotosUseCase {
    var firstPageCategories: [ILPhotosCategory?] = []
    var nextPageCallCount = 0
    var firstPageError: Error?
    var nextPageError: Error?
    var hasMoreAfterFirstPage = true
    /// Per-category artificial latency (nanoseconds) for `loadFirstPage`.
    var firstPageDelays: [ILPhotosCategory: UInt64] = [:]

    private static func photo(_ id: String) -> ILPhotosPhotoEntity {
        ILPhotosPhotoEntity(
            id: id,
            category: .temple,
            title: "title-\(id)",
            place: "place-\(id)",
            thumbnailURL: "http://host/thumb/\(id).jpg",
            imageURL: "http://host/full/\(id).jpg"
        )
    }

    func loadFirstPage(category: ILPhotosCategory?) async throws -> ILPhotosEntity {
        firstPageCategories.append(category)
        if let category, let delay = firstPageDelays[category] {
            try await Task.sleep(nanoseconds: delay)
        }
        if let firstPageError { throw firstPageError }
        return ILPhotosEntity(
            photos: [Self.photo("g-1"), Self.photo("g-2")],
            selectedCategory: category,
            totalCount: 86,
            lastLoadedPage: 1,
            hasMore: hasMoreAfterFirstPage
        )
    }

    func loadNextPage(after entity: ILPhotosEntity) async throws -> ILPhotosEntity {
        nextPageCallCount += 1
        if let nextPageError { throw nextPageError }
        var updated = entity
        updated.photos += [Self.photo("g-3"), Self.photo("g-4")]
        updated.lastLoadedPage += 1
        updated.hasMore = false
        return updated
    }
}
