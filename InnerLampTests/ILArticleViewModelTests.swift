//
//  ILArticleViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILArticleViewModelTests: XCTestCase {

    private var mockUseCase: MockILArticleUseCase!
    private var sut: ILArticleViewModel!
    private var output: ILArticleViewModel.Output!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var saveTappedSubject: PassthroughSubject<Void, Never>!
    private var shareTappedSubject: PassthroughSubject<Void, Never>!
    private var nextArticleTappedSubject: PassthroughSubject<String, Never>!
    private var sourceTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILArticleUseCase()
        sut = ILArticleViewModel(useCase: mockUseCase, articleID: "art-1")
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        saveTappedSubject = PassthroughSubject<Void, Never>()
        shareTappedSubject = PassthroughSubject<Void, Never>()
        nextArticleTappedSubject = PassthroughSubject<String, Never>()
        sourceTappedSubject = PassthroughSubject<Void, Never>()

        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: makeInput())
    }

    override func tearDown() {
        cancellables = nil
        sourceTappedSubject = nil
        nextArticleTappedSubject = nil
        shareTappedSubject = nil
        saveTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        output = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILArticleViewModel.Input {
        ILArticleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            nextArticleTapped: nextArticleTappedSubject.eraseToAnyPublisher(),
            sourceTapped: sourceTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Waits until a `.success` model satisfying `predicate` is emitted (the load runs in a `Task`).
    private func waitForState(_ predicate: @escaping (ILArticleStateModel) -> Bool) -> XCTestExpectation {
        let expectation = expectation(description: "state matching predicate")
        var fulfilled = false
        output.state
            .sink { state in
                guard case .success(let model) = state else { return }
                // Always evaluate: `predicate` also records the latest model for the assertions.
                let matches = predicate(model)
                if matches, !fulfilled {
                    fulfilled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        return expectation
    }

    func test_init_stateIsLoadingUntilViewDidLoad() {
        var first: ViewState<ILArticleStateModel>?
        output.state
            .sink { if first == nil { first = $0 } }
            .store(in: &cancellables)

        guard case .loading? = first else { return XCTFail("Expected .loading first, got \(String(describing: first))") }
        XCTAssertTrue(mockUseCase.loadedIDs.isEmpty)
    }

    func test_viewDidLoad_loadsRequestedArticleFromServer() {
        let expectation = waitForState { $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(mockUseCase.loadedIDs, ["art-1"])
    }

    func test_viewDidLoad_mapsArticleToStateModel() {
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return !$0.nextArticles.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(latest?.headerCategory, "category-art-1")
        XCTAssertEqual(latest?.headerReadText, String(format: "article.readFormat".localized, 6))
        XCTAssertEqual(latest?.author, "author-art-1")
        XCTAssertEqual(latest?.authorInitials, "Iart-1")
        XCTAssertEqual(latest?.bodyParagraphs, ["art-1-p0", "art-1-p1"])
        XCTAssertEqual(latest?.quote, "art-1-quote")
        XCTAssertEqual(latest?.quoteSource, "art-1-src")
        XCTAssertEqual(latest?.isSaved, false)
        XCTAssertEqual(latest?.saveButtonTitle, "article.save".localized)
        XCTAssertEqual(latest?.shareButtonTitle, "article.share".localized)
        XCTAssertEqual(latest?.readMoreTitle, "article.readMore".localized)
        XCTAssertEqual(latest?.nextArticles.map(\.id), ["art-2", "art-3"])
        XCTAssertEqual(latest?.nextArticles.first?.categoryLabel, "CATEGORY-ART-2")
    }

    func test_viewDidLoad_withoutPublishedDate_showsOnlyReadText() {
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(latest?.dateReadText, String(format: "article.readFormat".localized, 6))
    }

    func test_viewDidLoad_withPublishedDate_formatsDayAndMonthInGMT() throws {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        components.year = 2026
        components.month = 9
        components.day = 18
        let date = try XCTUnwrap(components.date)
        mockUseCase.articles["art-1"] = ILArticleTestFixtures.detail(id: "art-1", publishedDate: date)
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(
            latest?.dateReadText,
            String(format: "article.dateFormat".localized, 18, 9) + " · " + String(format: "article.readFormat".localized, 6)
        )
    }

    func test_viewDidLoad_showsSourceAttribution() {
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(latest?.sourceText, String(format: "article.sourceFormat".localized, "Báo Giác Ngộ"))
        XCTAssertEqual(latest?.sourceURL, "https://example.com/original")
    }

    func test_viewDidLoad_articleWithoutSourceName_hidesSourceLine() {
        mockUseCase.articles["art-1"] = ILArticleTestFixtures.detail(id: "art-1", sourceName: "", sourceURL: nil)
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(latest?.sourceText, "")
        XCTAssertNil(latest?.sourceURL)
    }

    func test_viewDidLoad_failure_emitsFailureState() {
        mockUseCase.loadError = ILCatalogError.notFound
        let expectation = expectation(description: "failure emitted")
        output.state
            .sink { state in
                if case .failure(let error) = state, case ILCatalogError.notFound = error { expectation.fulfill() }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [expectation], timeout: 2)
    }

    func test_viewDidLoad_nextArticlesFailure_stillShowsArticle() {
        mockUseCase.nextArticles = []
        var latest: ILArticleStateModel?
        let expectation = waitForState { latest = $0; return $0.title == "title-art-1" }

        viewDidLoadSubject.send(())
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(latest?.nextArticles.count, 0)
    }

    func test_saveTapped_togglesSavedStateAndLabel() {
        var latest: ILArticleStateModel?
        let loaded = waitForState { latest = $0; return $0.title == "title-art-1" }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        saveTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleSavedIDs, ["art-1"])
        XCTAssertEqual(latest?.isSaved, true)
        XCTAssertEqual(latest?.saveButtonTitle, "article.saved".localized)

        saveTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleSavedIDs, ["art-1", "art-1"])
        XCTAssertEqual(latest?.isSaved, false)
        XCTAssertEqual(latest?.saveButtonTitle, "article.save".localized)
    }

    func test_saveTapped_beforeArticleLoaded_isIgnored() {

        saveTappedSubject.send(())

        XCTAssertTrue(mockUseCase.toggleSavedIDs.isEmpty)
    }

    func test_nextArticleTapped_loadsTappedArticle() {
        var latest: ILArticleStateModel?
        let first = waitForState { latest = $0; return $0.title == "title-art-1" }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        let second = waitForState { latest = $0; return $0.title == "title-art-2" }
        nextArticleTappedSubject.send("art-2")
        wait(for: [second], timeout: 2)

        XCTAssertEqual(mockUseCase.loadedIDs, ["art-1", "art-2"])
        XCTAssertEqual(latest?.headerCategory, "category-art-2")
    }

    func test_nextArticleTapped_currentArticle_isIgnored() {
        var latest: ILArticleStateModel?
        let first = waitForState { latest = $0; return $0.title == "title-art-1" }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        nextArticleTappedSubject.send("art-1")

        XCTAssertEqual(mockUseCase.loadedIDs, ["art-1"])
        XCTAssertEqual(latest?.title, "title-art-1")
    }

    func test_sourceTapped_firesOpenURLNavigationEvent() {
        var latest: ILArticleStateModel?
        let loaded = waitForState { latest = $0; return $0.title == "title-art-1" }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)
        XCTAssertNotNil(latest)
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        sourceTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openURL("https://example.com/original"))
    }

    func test_sourceTapped_withoutLink_doesNothing() {
        mockUseCase.articles["art-1"] = ILArticleTestFixtures.detail(id: "art-1", sourceURL: nil)
        let loaded = waitForState { $0.title == "title-art-1" }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        sourceTappedSubject.send(())

        XCTAssertNil(receivedEvent)
    }

    func test_backTapped_firesBackNavigationEvent() {
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_shareTapped_firesShareNavigationEvent() {
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        shareTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .share)
    }
}

// MARK: - Mock ILArticleUseCase
/// Serves 3 fixed articles; `loadError` makes every load fail.
final class MockILArticleUseCase: ILArticleUseCase {
    var loadedIDs: [String] = []
    var toggleSavedIDs: [String] = []
    var loadError: Error?
    var articles: [String: ILArticleItemEntity] = [
        "art-1": ILArticleTestFixtures.detail(id: "art-1"),
        "art-2": ILArticleTestFixtures.detail(id: "art-2"),
        "art-3": ILArticleTestFixtures.detail(id: "art-3")
    ]
    var nextArticles: [ILArticleSummaryEntity] = [
        ILArticleTestFixtures.summary(id: "art-2"),
        ILArticleTestFixtures.summary(id: "art-3")
    ]

    func getInitialState(articleID: String) -> ILArticleEntity {
        ILArticleEntity(currentArticleID: articleID)
    }

    func loadArticle(id: String) async throws -> ILArticleItemEntity {
        loadedIDs.append(id)
        if let loadError { throw loadError }
        guard let article = articles[id] else { throw ILCatalogError.notFound }
        return article
    }

    func loadNextArticles(excluding id: String) async -> [ILArticleSummaryEntity] {
        nextArticles.filter { $0.id != id }
    }

    func toggleSave(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity {
        toggleSavedIDs.append(id)
        var updated = entity
        if updated.savedArticleIDs.contains(id) {
            updated.savedArticleIDs.remove(id)
        } else {
            updated.savedArticleIDs.insert(id)
        }
        return updated
    }
}
