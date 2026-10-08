//
//  ILArticlesViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILArticlesViewModelTests: XCTestCase {

    private var mockUseCase: MockILArticlesUseCase!
    private var sut: ILArticlesViewModel!
    private var output: ILArticlesViewModel.Output!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var articleTappedSubject: PassthroughSubject<String, Never>!
    private var loadMoreTriggeredSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILArticlesUseCase()
        sut = ILArticlesViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        articleTappedSubject = PassthroughSubject<String, Never>()
        loadMoreTriggeredSubject = PassthroughSubject<Void, Never>()

        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: makeInput())
    }

    override func tearDown() {
        cancellables = nil
        loadMoreTriggeredSubject = nil
        articleTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        output = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILArticlesViewModel.Input {
        ILArticlesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            articleTapped: articleTappedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher()
        )
    }

    /// Fulfilled the first time a `.success` model satisfying `predicate` is emitted. `predicate`
    /// runs for every emission, so it can also record the latest model for the assertions.
    private func waitForState(_ predicate: @escaping (ILArticlesStateModel) -> Bool) -> XCTestExpectation {
        let expectation = expectation(description: "state matching predicate")
        var fulfilled = false
        output.state
            .sink { state in
                guard case .success(let model) = state else { return }
                let matches = predicate(model)
                if matches, !fulfilled {
                    fulfilled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        return expectation
    }

    func test_init_startsEmptyWithoutLoading() {
        var latest: ILArticlesStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)

        XCTAssertEqual(latest, .initial)
        XCTAssertEqual(mockUseCase.firstPageCallCount, 0)
    }

    func test_viewDidLoad_loadsFirstPageWithSubtitle() {
        var latest: ILArticlesStateModel?
        let loaded = waitForState { latest = $0; return !$0.articles.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertEqual(mockUseCase.firstPageCallCount, 1)
        XCTAssertEqual(latest?.articles.count, 2)
        XCTAssertEqual(latest?.articles.first?.id, "art-1")
        XCTAssertEqual(latest?.articles.first?.readText, String(format: "articles.readFormat".localized, 6))
        XCTAssertEqual(latest?.subtitle, String(format: "articles.header.subtitleFormat".localized, 2, 4))
        XCTAssertEqual(latest?.hasMore, true)
        XCTAssertEqual(latest?.isLoadingMore, false)
    }

    func test_viewDidLoad_showsLoadingFooterWhileFirstPageIsInFlight() {
        var sawLoading = false
        let loaded = waitForState { if $0.isLoadingMore { sawLoading = true }; return !$0.articles.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertTrue(sawLoading)
    }

    func test_viewDidLoad_failure_clearsSpinnerThenEmitsFailure() {
        mockUseCase.firstPageError = ILCatalogError.offline
        var latest: ILArticlesStateModel?
        var order: [String] = []
        output.state
            .sink { state in
                switch state {
                case .success(let model):
                    latest = model
                    order.append(model.isLoadingMore ? "loading" : "idle")
                case .failure:
                    order.append("failure")
                default:
                    break
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
        XCTAssertEqual(latest?.isLoadingMore, false, "The footer spinner must not stay on after a failure")
    }

    func test_articleTapped_firesOpenArticleNavigationEvent() {
        var receivedEvent: ILArticlesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        articleTappedSubject.send("art-3")

        XCTAssertEqual(receivedEvent, .openArticle(id: "art-3"))
    }

    func test_backTapped_firesBackNavigationEvent() {
        var receivedEvent: ILArticlesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_loadMore_whenHasMore_appendsNextPage() {
        var latest: ILArticlesStateModel?
        let firstPage = waitForState { latest = $0; return $0.articles.count == 2 }
        viewDidLoadSubject.send(())
        wait(for: [firstPage], timeout: 2)

        let merged = waitForState { latest = $0; return $0.articles.count == 4 }
        loadMoreTriggeredSubject.send(())
        wait(for: [merged], timeout: 2)

        XCTAssertEqual(mockUseCase.nextPageCallCount, 1)
        XCTAssertEqual(latest?.articles.map(\.id), ["art-1", "art-2", "art-3", "art-4"])
        XCTAssertEqual(latest?.subtitle, String(format: "articles.header.subtitleFormat".localized, 4, 4))
        XCTAssertEqual(latest?.hasMore, false)
        XCTAssertEqual(latest?.isLoadingMore, false)
    }

    func test_loadMore_whenNoMore_doesNotCallUseCase() {
        mockUseCase.hasMoreAfterFirstPage = false
        var latest: ILArticlesStateModel?
        let firstPage = waitForState { latest = $0; return $0.articles.count == 2 }
        viewDidLoadSubject.send(())
        wait(for: [firstPage], timeout: 2)
        XCTAssertEqual(latest?.hasMore, false)

        loadMoreTriggeredSubject.send(())

        XCTAssertEqual(mockUseCase.nextPageCallCount, 0)
    }

    func test_loadMore_beforeFirstPage_doesNotCallUseCase() {
        loadMoreTriggeredSubject.send(())

        XCTAssertEqual(mockUseCase.nextPageCallCount, 0)
    }

    func test_loadMore_whenAlreadyLoading_doesNotDuplicate() {
        var latest: ILArticlesStateModel?
        let firstPage = waitForState { latest = $0; return $0.articles.count == 2 }
        viewDidLoadSubject.send(())
        wait(for: [firstPage], timeout: 2)
        let merged = waitForState { latest = $0; return $0.articles.count == 4 }

        // Two rapid triggers — the guard must collapse them into a single use-case call.
        loadMoreTriggeredSubject.send(())
        loadMoreTriggeredSubject.send(())
        wait(for: [merged], timeout: 2)

        XCTAssertEqual(mockUseCase.nextPageCallCount, 1)
        XCTAssertEqual(latest?.articles.count, 4)
    }

    func test_loadMore_failure_keepsLoadedRowsAndClearsSpinner() {
        var latest: ILArticlesStateModel?
        let firstPage = waitForState { latest = $0; return $0.articles.count == 2 }
        viewDidLoadSubject.send(())
        wait(for: [firstPage], timeout: 2)
        mockUseCase.nextPageError = ILCatalogError.offline
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { if case .failure = $0 { failed.fulfill() } }
            .store(in: &cancellables)

        loadMoreTriggeredSubject.send(())
        wait(for: [failed], timeout: 2)

        XCTAssertEqual(latest?.articles.count, 2)
        XCTAssertEqual(latest?.isLoadingMore, false)
    }
}

// MARK: - Mock ILArticlesUseCase
/// Serves a 2-row first page and a 2-row second page of a 4-article catalog.
final class MockILArticlesUseCase: ILArticlesUseCase {
    var firstPageCallCount = 0
    var nextPageCallCount = 0
    var firstPageError: Error?
    var nextPageError: Error?
    var hasMoreAfterFirstPage = true

    private static func row(_ id: String, minutes: Int) -> ILArticlesItemEntity {
        ILArticlesItemEntity(id: id, category: "cat-\(id)", title: "title-\(id)", author: "author-\(id)", readMinutes: minutes)
    }

    func loadFirstPage() async throws -> ILArticlesEntity {
        firstPageCallCount += 1
        if let firstPageError { throw firstPageError }
        return ILArticlesEntity(
            articles: [Self.row("art-1", minutes: 6), Self.row("art-2", minutes: 4)],
            loadedCount: 2,
            totalCount: 4,
            lastLoadedPage: 1,
            hasMore: hasMoreAfterFirstPage
        )
    }

    func loadNextPage(after entity: ILArticlesEntity) async throws -> ILArticlesEntity {
        nextPageCallCount += 1
        if let nextPageError { throw nextPageError }
        return ILArticlesEntity(
            articles: entity.articles + [Self.row("art-3", minutes: 5), Self.row("art-4", minutes: 5)],
            loadedCount: 4,
            totalCount: 4,
            lastLoadedPage: entity.lastLoadedPage + 1,
            hasMore: false
        )
    }
}
