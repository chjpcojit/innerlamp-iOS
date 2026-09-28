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
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var saveTappedSubject: PassthroughSubject<Void, Never>!
    private var shareTappedSubject: PassthroughSubject<Void, Never>!
    private var nextArticleTappedSubject: PassthroughSubject<String, Never>!

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
    }

    override func tearDown() {
        cancellables = nil
        nextArticleTappedSubject = nil
        shareTappedSubject = nil
        saveTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
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
            nextArticleTapped: nextArticleTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILArticleStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILArticleStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsRequestedArticle() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.headerCategory, "Giáo lý căn bản")
        XCTAssertEqual(state?.title, "Tứ Diệu Đế")
        XCTAssertEqual(state?.headerReadText, String(format: "article.readFormat".localized, 6))
        XCTAssertEqual(state?.bodyParagraphs.count, 2)
        XCTAssertEqual(state?.isSaved, false)
        XCTAssertEqual(state?.saveButtonTitle, "article.save".localized)
        XCTAssertEqual(state?.shareButtonTitle, "article.share".localized)
        XCTAssertEqual(state?.readMoreTitle, "article.readMore".localized)
        // 2 bài "Đọc tiếp" kế tiếp art-1.
        XCTAssertEqual(state?.nextArticles.map(\.id), ["art-2", "art-3"])
    }

    func test_saveTapped_togglesSavedStateAndLabel() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        saveTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleSavedIDs, ["art-1"])
        let state = latest()
        XCTAssertEqual(state?.isSaved, true)
        XCTAssertEqual(state?.saveButtonTitle, "article.saved".localized)

        saveTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleSavedIDs, ["art-1", "art-1"])
        XCTAssertEqual(latest()?.isSaved, false)
        XCTAssertEqual(latest()?.saveButtonTitle, "article.save".localized)
    }

    func test_nextArticleTapped_switchesArticle() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        nextArticleTappedSubject.send("art-2")

        XCTAssertEqual(mockUseCase.selectedIDs, ["art-2"])
        let state = latest()
        XCTAssertEqual(state?.headerCategory, "Thực hành")
        XCTAssertEqual(state?.title, "Chánh niệm")
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_shareTapped_firesShareNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILArticleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        shareTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .share)
    }
}

// MARK: - Mock ILArticleUseCase
/// Catalog cố định 3 bài viết — đủ để test chuyển bài và danh sách "Đọc tiếp" mà không cần dựng
/// cả 5 bài của prototype.
final class MockILArticleUseCase: ILArticleUseCase {
    var getInitialStateCalled = false
    var toggleSavedIDs: [String] = []
    var selectedIDs: [String] = []

    private static func makeArticle(_ id: String, category: String, title: String, readMinutes: Int = 6) -> ILArticleItemEntity {
        ILArticleItemEntity(
            id: id,
            category: category,
            title: title,
            author: "\(id)-author",
            authorInitials: "\(id)X",
            date: "\(id)-date",
            readMinutes: readMinutes,
            bodyParagraphs: ["\(id)-p0", "\(id)-p1"],
            quote: "\(id)-quote",
            quoteSource: "\(id)-src"
        )
    }

    private static var catalog: [ILArticleItemEntity] {
        [
            makeArticle("art-1", category: "Giáo lý căn bản", title: "Tứ Diệu Đế"),
            makeArticle("art-2", category: "Thực hành", title: "Chánh niệm"),
            makeArticle("art-3", category: "Lễ hội", title: "Vu Lan")
        ]
    }

    func getInitialState(articleID: String) -> ILArticleEntity {
        getInitialStateCalled = true
        return ILArticleEntity(articles: Self.catalog, currentArticleID: articleID, savedArticleIDs: [])
    }

    func currentArticle(in entity: ILArticleEntity) -> ILArticleItemEntity? {
        entity.articles.first { $0.id == entity.currentArticleID }
    }

    func nextArticles(after currentID: String, in entity: ILArticleEntity) -> [ILArticleItemEntity] {
        guard !entity.articles.isEmpty,
              let index = entity.articles.firstIndex(where: { $0.id == currentID }) else {
            return []
        }
        return [1, 2].map { entity.articles[(index + $0) % entity.articles.count] }
    }

    func selectArticle(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity {
        selectedIDs.append(id)
        var updated = entity
        updated.currentArticleID = id
        return updated
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
