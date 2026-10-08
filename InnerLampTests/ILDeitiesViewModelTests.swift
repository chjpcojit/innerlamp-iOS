//
//  ILDeitiesViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILDeitiesViewModelTests: XCTestCase {

    private var mockUseCase: MockILDeitiesUseCase!
    private var sut: ILDeitiesViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var filterSelectedSubject: PassthroughSubject<ILDeityKind?, Never>!
    private var deityTappedSubject: PassthroughSubject<String, Never>!
    private var retryTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILDeitiesUseCase()
        sut = ILDeitiesViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        filterSelectedSubject = PassthroughSubject<ILDeityKind?, Never>()
        deityTappedSubject = PassthroughSubject<String, Never>()
        retryTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        filterSelectedSubject = nil
        deityTappedSubject = nil
        retryTappedSubject = nil
        states = []
        onSettled = nil
        isBound = false
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILDeitiesViewModel.Input {
        ILDeitiesViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            deityTapped: deityTappedSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher()
        )
    }

    private var states: [ViewState<ILDeitiesStateModel>] = []
    private var onSettled: (() -> Void)?
    private var isBound = false

    /// Binds `transform(input:)` once per test and records every emitted state.
    private func bindIfNeeded() {
        guard !isBound else { return }
        isBound = true
        sut.transform(input: makeInput()).state
            .sink { [weak self] state in
                self?.states.append(state)
                switch state {
                case .success, .failure: self?.onSettled?()
                case .idle, .loading: break
                }
            }
            .store(in: &cancellables)
    }

    /// Fires `trigger`, then waits until the next `.success` / `.failure`.
    @discardableResult
    private func loadAndWait(trigger: () -> Void) -> ViewState<ILDeitiesStateModel>? {
        bindIfNeeded()
        let settled = expectation(description: "load settled")
        settled.assertForOverFulfill = false
        onSettled = { settled.fulfill() }
        trigger()
        wait(for: [settled], timeout: 1)
        onSettled = nil
        return states.last
    }

    private func latestModel() -> ILDeitiesStateModel? {
        guard case .success(let model) = states.last else { return nil }
        return model
    }

    private func loadedModel() -> ILDeitiesStateModel? {
        loadAndWait { viewDidLoadSubject.send(()) }
        return latestModel()
    }

    // MARK: - Loading

    func test_viewDidLoad_emitsLoadingThenServerCatalogWithAllFilterSelected() {
        let state = loadedModel()

        XCTAssertEqual(mockUseCase.loadCallCount, 1)
        XCTAssertTrue(states.contains { if case .loading = $0 { return true } else { return false } })
        XCTAssertEqual(state?.items.count, 3)
        XCTAssertEqual(state?.filters.count, 3)
        XCTAssertEqual(state?.filters.first?.isSelected, true)
        XCTAssertNil(state?.filters.first?.kind ?? nil)
        XCTAssertEqual(state?.subtitle, String(format: "deities.header.subtitleFormat".localized, 3))
        XCTAssertEqual(state?.emptyTitle, "")
    }

    func test_viewDidLoad_mapsSummaryFields_andMemorialPlaceholder() {
        let first = loadedModel()?.items.first

        XCTAssertEqual(first?.id, "buddha-1")
        XCTAssertEqual(first?.name, "name-buddha-1")
        XCTAssertEqual(first?.role, "virtue-buddha-1")
        XCTAssertEqual(first?.kindLabel, "deity.kind.buddha".localized)
        XCTAssertEqual(first?.memorialText, "deities.memorialUpdating".localized)
    }

    func test_viewDidLoad_emptyCatalog_showsUpdatingState() {
        mockUseCase.result = .success(.empty)

        let state = loadedModel()

        XCTAssertEqual(state?.items.isEmpty, true)
        XCTAssertEqual(state?.subtitle, "deities.updating".localized)
        XCTAssertEqual(state?.emptyTitle, "deities.updating".localized)
        XCTAssertEqual(state?.emptyMessage, "deities.empty.message".localized)
    }

    func test_viewDidLoad_failure_emitsFailure() {
        mockUseCase.result = .failure(ILCatalogError.offline)

        let state = loadAndWait { viewDidLoadSubject.send(()) }

        guard case .failure(let error) = state else { return XCTFail("Expected failure") }
        guard case ILCatalogError.offline = error else { return XCTFail("Unexpected error \(error)") }
    }

    func test_retryTapped_reloadsCatalog() {
        mockUseCase.result = .failure(ILCatalogError.offline)
        loadAndWait { viewDidLoadSubject.send(()) }
        mockUseCase.result = .success(MockILDeitiesUseCase.catalog)

        let state = loadAndWait { retryTappedSubject.send(()) }

        XCTAssertEqual(mockUseCase.loadCallCount, 2)
        guard case .success(let model) = state else { return XCTFail("Expected success") }
        XCTAssertEqual(model.items.count, 3)
    }

    // MARK: - Filters

    func test_filterSelected_buddha_filtersItemsAndMovesSelection() {
        _ = loadedModel()

        filterSelectedSubject.send(.buddha)

        let state = latestModel()
        XCTAssertEqual(state?.items.count, 1)
        XCTAssertEqual(state?.items.first?.kind, .buddha)
        XCTAssertEqual(state?.filters.first { $0.isSelected }?.kind, .buddha)
    }

    func test_filterSelected_bodhisattva_filtersItemsAndMovesSelection() {
        _ = loadedModel()

        filterSelectedSubject.send(.bodhisattva)

        let state = latestModel()
        XCTAssertEqual(state?.items.count, 2)
        XCTAssertEqual(state?.items.allSatisfy { $0.kind == .bodhisattva }, true)
        XCTAssertEqual(state?.filters.first { $0.isSelected }?.kind, .bodhisattva)
    }

    func test_filterSelected_withNoMatches_showsUpdatingEmptyState() {
        mockUseCase.result = .success(ILDeitiesEntity(deities: [MockILDeitiesUseCase.summary(id: "bodhisattva-1", kind: .bodhisattva)]))
        _ = loadedModel()

        filterSelectedSubject.send(.buddha)

        let state = latestModel()
        XCTAssertEqual(state?.items.isEmpty, true)
        XCTAssertEqual(state?.emptyTitle, "deities.updating".localized)
        XCTAssertEqual(state?.subtitle, String(format: "deities.header.subtitleFormat".localized, 1))
    }

    func test_filterSelected_nil_resetsToAllDeities() {
        _ = loadedModel()
        filterSelectedSubject.send(.buddha)

        filterSelectedSubject.send(nil)

        let state = latestModel()
        XCTAssertEqual(state?.items.count, 3)
        XCTAssertEqual(state?.filters.first?.isSelected, true)
    }

    func test_filterSelected_sameKind_isIgnored() {
        _ = loadedModel()
        filterSelectedSubject.send(.buddha)
        let requestCount = mockUseCase.requestedKinds.count

        filterSelectedSubject.send(.buddha)

        // Chạm lại chip đang chọn không lọc lại.
        XCTAssertEqual(mockUseCase.requestedKinds.count, requestCount)
    }

    // MARK: - Navigation

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILDeitiesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_deityTapped_firesOpenDeityEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILDeitiesNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        deityTappedSubject.send("bodhisattva-2")

        XCTAssertEqual(receivedEvent, .openDeity(id: "bodhisattva-2"))
    }
}

// MARK: - UseCase tests

final class ILDeitiesUseCaseTests: XCTestCase {

    private var repository: MockDeitiesCatalogRepository!
    private var sut: ILDeitiesUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockDeitiesCatalogRepository()
        sut = ILDeitiesUseCaseImpl(deityCatalogRepository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    private func summary(_ id: String, _ kind: ILDeityKind) -> ILDeitySummaryEntity {
        MockILDeitiesUseCase.summary(id: id, kind: kind)
    }

    func test_loadDeities_readsBothTypesFromEveryPage() async throws {
        repository.pages = [
            1: ILCatalogPageEntity(items: [summary("b1", .buddha), summary("bo1", .bodhisattva)], page: 1, hasMore: true),
            2: ILCatalogPageEntity(items: [summary("bo2", .bodhisattva)], page: 2, hasMore: false)
        ]

        let entity = try await sut.loadDeities()

        XCTAssertEqual(entity.deities.map(\.id), ["b1", "bo1", "bo2"])
        XCTAssertEqual(repository.requestedPages, [1, 2])
    }

    func test_loadDeities_deduplicatesIdsAcrossPages() async throws {
        repository.pages = [
            1: ILCatalogPageEntity(items: [summary("bo1", .bodhisattva), summary("bo2", .bodhisattva)], page: 1, hasMore: true),
            2: ILCatalogPageEntity(items: [summary("bo2", .bodhisattva), summary("bo3", .bodhisattva)], page: 2, hasMore: false)
        ]

        let entity = try await sut.loadDeities()

        XCTAssertEqual(entity.deities.map(\.id), ["bo1", "bo2", "bo3"])
    }

    func test_loadDeities_pagedListFails_fallsBackToTopList() async throws {
        repository.topResult = .success([summary("b1", .buddha), summary("bo1", .bodhisattva)])
        repository.pageError = ILCatalogError.offline

        let entity = try await sut.loadDeities()

        XCTAssertEqual(entity.deities.map(\.id), ["b1", "bo1"])
    }

    func test_loadDeities_bothSourcesFail_throws() async {
        repository.topResult = .failure(ILCatalogError.offline)
        repository.pageError = ILCatalogError.offline

        do {
            _ = try await sut.loadDeities()
            XCTFail("Expected ILCatalogError.offline")
        } catch ILCatalogError.offline {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func test_loadDeities_emptyServer_returnsEmptyCatalog() async throws {
        let entity = try await sut.loadDeities()

        XCTAssertTrue(entity.deities.isEmpty)
    }

    func test_deities_filtersByKind() {
        let entity = ILDeitiesEntity(deities: [summary("b1", .buddha), summary("bo1", .bodhisattva), summary("bo2", .bodhisattva)])

        XCTAssertEqual(sut.deities(in: entity, kind: nil).count, 3)
        XCTAssertEqual(sut.deities(in: entity, kind: .buddha).map(\.id), ["b1"])
        XCTAssertEqual(sut.deities(in: entity, kind: .bodhisattva).map(\.id), ["bo1", "bo2"])
    }
}

// MARK: - Mocks

/// Configurable server catalog for `ILDeitiesUseCaseImpl` — top list + paged deities.
private final class MockDeitiesCatalogRepository: ILDeityCatalogRepository {
    var topResult: Result<[ILDeitySummaryEntity], Error> = .success([])
    var pages: [Int: ILCatalogPageEntity<ILDeitySummaryEntity>] = [:]
    var pageError: Error?
    private(set) var requestedPages: [Int] = []

    func loadTopDeities() async throws -> [ILDeitySummaryEntity] {
        try topResult.get()
    }

    func loadDeities(page: Int) async throws -> ILCatalogPageEntity<ILDeitySummaryEntity> {
        requestedPages.append(page)
        if let pageError { throw pageError }
        return pages[page] ?? ILCatalogPageEntity(items: [], page: page, hasMore: false)
    }

    func loadDeityDetail(id: String) async throws -> ILDeityEntity {
        throw ILCatalogError.notFound
    }
}

/// Catalog cố định 3 vị (1 Phật + 2 Bồ Tát) — đủ để test lọc theo loại.
final class MockILDeitiesUseCase: ILDeitiesUseCase {
    var result: Result<ILDeitiesEntity, Error> = .success(MockILDeitiesUseCase.catalog)
    private(set) var loadCallCount = 0
    private(set) var requestedKinds: [ILDeityKind?] = []

    static func summary(id: String, kind: ILDeityKind) -> ILDeitySummaryEntity {
        ILDeitySummaryEntity(
            id: id,
            kind: kind,
            nameVi: "name-\(id)",
            nameSanskrit: "",
            nameChinese: "",
            titleHonorific: "",
            thumbnailURL: "",
            imageURL: "",
            coreVirtue: "virtue-\(id)",
            pureLand: ""
        )
    }

    static let catalog = ILDeitiesEntity(deities: [
        summary(id: "buddha-1", kind: .buddha),
        summary(id: "bodhisattva-1", kind: .bodhisattva),
        summary(id: "bodhisattva-2", kind: .bodhisattva)
    ])

    func loadDeities() async throws -> ILDeitiesEntity {
        loadCallCount += 1
        return try result.get()
    }

    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeitySummaryEntity] {
        requestedKinds.append(kind)
        guard let kind else { return entity.deities }
        return entity.deities.filter { $0.kind == kind }
    }
}
