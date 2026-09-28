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
    }

    override func tearDown() {
        cancellables = nil
        loadMoreTriggeredSubject = nil
        articleTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
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

    /// Subscribes once to `output.state` and returns a closure returning the latest model.
    private func observeLatestState() -> () -> ILArticlesStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILArticlesStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsArticlesWithSubtitle() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.articles.count, 2)
        XCTAssertEqual(state?.articles.first?.id, "art-1")
        XCTAssertEqual(state?.articles.first?.readText, String(format: "articles.readFormat".localized, 6))
        XCTAssertEqual(
            state?.subtitle,
            String(format: "articles.header.subtitleFormat".localized, 2, mockUseCase.totalCount)
        )
        XCTAssertTrue(state?.hasMore ?? false)
        XCTAssertFalse(state?.isLoadingMore ?? true)
    }

    func test_articleTapped_firesOpenArticleNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILArticlesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        articleTappedSubject.send("art-3")

        XCTAssertEqual(receivedEvent, .openArticle(id: "art-3"))
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILArticlesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_loadMore_whenHasMore_setsLoadingThenSettles() {
        let output = sut.transform(input: makeInput())
        var sawLoading = false
        var settled = false
        let expectation = expectation(description: "load more settles")
        output.state
            .sink { state in
                guard case .success(let model) = state else { return }
                if model.isLoadingMore { sawLoading = true }
                if sawLoading, !model.isLoadingMore, !settled {
                    settled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        loadMoreTriggeredSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(mockUseCase.loadMoreCalled)
        XCTAssertTrue(sawLoading)
    }

    func test_loadMore_whenNoMore_doesNotCallUseCase() {
        mockUseCase.totalCount = 2 // equals the catalog count, so hasMore == false.
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        XCTAssertFalse(latest()?.hasMore ?? true)

        loadMoreTriggeredSubject.send(())

        XCTAssertFalse(mockUseCase.loadMoreCalled)
    }

    func test_loadMore_whenAlreadyLoading_doesNotDuplicate() {
        let output = sut.transform(input: makeInput())
        var sawLoading = false
        var settled = false
        let expectation = expectation(description: "load more settles")
        output.state
            .sink { state in
                guard case .success(let model) = state else { return }
                if model.isLoadingMore { sawLoading = true }
                if sawLoading, !model.isLoadingMore, !settled {
                    settled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        // Two rapid triggers — the guard must collapse them into a single use-case call.
        loadMoreTriggeredSubject.send(())
        loadMoreTriggeredSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(mockUseCase.loadMoreCallCount, 1)
    }
}

// MARK: - Mock ILArticlesUseCase
/// A two-article catalog is enough to exercise the list, subtitle formatting, and load-more guard.
final class MockILArticlesUseCase: ILArticlesUseCase {
    var getInitialStateCalled = false
    var loadMoreCalled = false
    var loadMoreCallCount = 0
    var totalCount = 60

    private static var catalog: [ILArticlesItemEntity] {
        [
            ILArticlesItemEntity(id: "art-1", category: "Giáo lý căn bản", title: "Tứ Diệu Đế", author: "Thầy Minh Đạo", readMinutes: 6),
            ILArticlesItemEntity(id: "art-2", category: "Thực hành", title: "Chánh niệm", author: "Sư cô Tâm Nguyện", readMinutes: 4)
        ]
    }

    func getInitialState() -> ILArticlesEntity {
        getInitialStateCalled = true
        return ILArticlesEntity(
            articles: Self.catalog,
            loadedCount: Self.catalog.count,
            totalCount: totalCount
        )
    }

    func loadMoreArticles() async throws {
        loadMoreCalled = true
        loadMoreCallCount += 1
        // No-op stub — mirrors the real impl's stub shape; the ViewModel re-emits on success.
    }
}
