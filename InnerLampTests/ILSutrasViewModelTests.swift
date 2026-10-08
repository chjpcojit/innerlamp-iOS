//
//  ILSutrasViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSutrasViewModelTests: XCTestCase {

    private var repository: MockILSutraRepository!
    private var sut: ILSutrasViewModel!
    private var output: ILSutrasViewModel.Output!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var categorySelectedSubject: PassthroughSubject<ILSutraCategory, Never>!
    private var lengthSelectedSubject: PassthroughSubject<ILSutraLengthFilter, Never>!
    private var queryChangedSubject: PassthroughSubject<String, Never>!
    private var sutraTappedSubject: PassthroughSubject<String, Never>!
    private var loadMoreTriggeredSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        repository = MockILSutraRepository()
        sut = ILSutrasViewModel(useCase: ILSutrasUseCaseImpl(sutraRepository: repository))
        cancellables = []
        viewDidLoadSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        categorySelectedSubject = PassthroughSubject()
        lengthSelectedSubject = PassthroughSubject()
        queryChangedSubject = PassthroughSubject()
        sutraTappedSubject = PassthroughSubject()
        loadMoreTriggeredSubject = PassthroughSubject()
        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: ILSutrasViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            lengthSelected: lengthSelectedSubject.eraseToAnyPublisher(),
            queryChanged: queryChangedSubject.eraseToAnyPublisher(),
            sutraTapped: sutraTappedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreTriggeredSubject.eraseToAnyPublisher()
        ))
    }

    override func tearDown() {
        cancellables = nil
        output = nil
        sut = nil
        repository = nil
        super.tearDown()
    }

    /// Fulfilled the first time a `.success` model satisfying `predicate` is emitted. `predicate`
    /// runs for every emission, so it can also record the latest model for the assertions.
    private func waitForState(_ predicate: @escaping (ILSutrasStateModel) -> Bool) -> XCTestExpectation {
        let expectation = expectation(description: "state matching predicate")
        var fulfilled = false
        output.state
            .sink { state in
                guard case .success(let model) = state, predicate(model), !fulfilled else { return }
                fulfilled = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        return expectation
    }

    func test_viewDidLoad_loadsFirstPageWithDefaultFilter() {
        var latest: ILSutrasStateModel?
        let loaded = waitForState { latest = $0; return !$0.items.isEmpty && !$0.isLoadingMore }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertEqual(repository.listCalls.map(\.page), [1])
        XCTAssertEqual(repository.listCalls.first?.filter, ILSutraFilter())
        XCTAssertEqual(latest?.items.map(\.id), ["s0", "s1"])
        XCTAssertEqual(latest?.countText, String(format: "sutras.count.format".localized, 4))
        XCTAssertEqual(latest?.hasMore, true)
        XCTAssertEqual(latest?.categories.count, ILSutraCategory.allCases.count)
        XCTAssertEqual(latest?.categories.filter(\.isSelected).map(\.value), [.all])
        XCTAssertEqual(latest?.lengths.filter(\.isSelected).map(\.value), [.any])
    }

    func test_viewDidLoad_showsLoadingFooterWhileFirstPageIsInFlight() {
        var sawLoading = false
        let loaded = waitForState { if $0.isLoadingMore { sawLoading = true }; return !$0.items.isEmpty }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        XCTAssertTrue(sawLoading)
    }

    func test_viewDidLoad_failure_clearsSpinnerThenEmitsFailure() {
        repository.listError = ILCatalogError.offline
        var order: [String] = []
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { state in
                switch state {
                case .success(let model): order.append(model.isLoadingMore ? "loading" : "idle")
                case .failure:
                    order.append("failure")
                    failed.fulfill()
                default: break
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 2)

        XCTAssertEqual(Array(order.suffix(3)), ["loading", "idle", "failure"])
    }

    func test_categorySelected_restartsFromPageOneWithServerFilter() {
        var latest: ILSutrasStateModel?
        let first = waitForState { latest = $0; return $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        let filtered = waitForState { latest = $0; return $0.categories.contains { $0.isSelected && $0.value == .tradition(.mahayana) } && !$0.isLoadingMore }
        categorySelectedSubject.send(.tradition(.mahayana))
        wait(for: [filtered], timeout: 2)

        XCTAssertEqual(repository.listCalls.last?.page, 1)
        XCTAssertEqual(repository.listCalls.last?.filter, ILSutraFilter(category: .tradition(.mahayana), length: .any))
        XCTAssertEqual(latest?.items.map(\.id), ["s0", "s1"], "Rows are replaced, not appended to the old filter's rows")
    }

    func test_lengthSelected_restartsFromPageOneWithMaxMinutes() {
        let first = waitForState { $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        let filtered = waitForState { $0.lengths.contains { $0.isSelected && $0.value == .upTo15 } && !$0.isLoadingMore }
        lengthSelectedSubject.send(.upTo15)
        wait(for: [filtered], timeout: 2)

        XCTAssertEqual(repository.listCalls.last?.filter.length.maxMinutes, 15)
    }

    func test_categorySelected_sameChip_doesNotReload() {
        let first = waitForState { $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        categorySelectedSubject.send(.all)

        XCTAssertEqual(repository.listCalls.count, 1)
    }

    func test_staleResponse_afterFilterChange_isDropped() {
        // The first (unfiltered) request is held open until after the filter changes.
        var held: CheckedContinuation<ILSutraPageEntity, Never>?
        let requested = expectation(description: "first request in flight")
        repository.onLoadSutras = { page, filter in
            guard filter.category == .all else { return ILSutraPageEntity(items: [ILSutraFixtures.sutra(id: "fresh")], page: 1, totalCount: 1, hasMore: false) }
            return await withCheckedContinuation { continuation in
                held = continuation
                requested.fulfill()
            }
        }
        viewDidLoadSubject.send(())
        wait(for: [requested], timeout: 2)

        var latest: ILSutrasStateModel?
        let fresh = waitForState { latest = $0; return $0.items.map(\.id) == ["fresh"] }
        categorySelectedSubject.send(.dailyChant)
        wait(for: [fresh], timeout: 2)

        held?.resume(returning: ILSutraFixtures.page(1, total: 4))
        let settled = expectation(description: "stale response processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
        wait(for: [settled], timeout: 2)

        XCTAssertEqual(latest?.items.map(\.id), ["fresh"])
    }

    func test_loadMore_whenHasMore_appendsNextPage() {
        var latest: ILSutrasStateModel?
        let first = waitForState { latest = $0; return $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        let merged = waitForState { latest = $0; return $0.items.count == 4 && !$0.isLoadingMore }
        loadMoreTriggeredSubject.send(())
        wait(for: [merged], timeout: 2)

        XCTAssertEqual(repository.listCalls.map(\.page), [1, 2])
        XCTAssertEqual(latest?.items.map(\.id), ["s0", "s1", "s2", "s3"])
        XCTAssertEqual(latest?.hasMore, false)
    }

    func test_loadMore_whenNoMore_orBeforeFirstPage_doesNotCallRepository() {
        loadMoreTriggeredSubject.send(())
        XCTAssertEqual(repository.listCalls.count, 0)

        repository.total = 2
        let first = waitForState { $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [first], timeout: 2)

        loadMoreTriggeredSubject.send(())
        XCTAssertEqual(repository.listCalls.count, 1)
    }

    func test_queryChanged_restartsFromPageOneWithServerKeyword_afterDebounce() {
        let firstLoad = waitForState { $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [firstLoad], timeout: 2)

        var latest: ILSutrasStateModel?
        repository.onLoadSutras = { page, filter in
            ILSutraPageEntity(
                items: filter.query == "đại bi" ? [ILSutraFixtures.sutra(id: "a", title: "Chú Đại Bi")] : [],
                page: page, totalCount: 1, hasMore: false
            )
        }
        let searched = waitForState { latest = $0; return $0.items.map(\.id) == ["a"] && !$0.isLoadingMore }
        // Typing bursts collapse into one request for the last keyword.
        queryChangedSubject.send("đ")
        queryChangedSubject.send("đại")
        queryChangedSubject.send("  đại bi  ")
        wait(for: [searched], timeout: 2)

        XCTAssertEqual(repository.listCalls.count, 2, "Initial page + exactly one search request")
        XCTAssertEqual(repository.listCalls.last?.page, 1)
        XCTAssertEqual(repository.listCalls.last?.filter.query, "đại bi")
        XCTAssertEqual(latest?.countText, String(format: "sutras.count.matchedFormat".localized, 1))
    }

    func test_queryChanged_blankKeyword_doesNotCallServerWhenNothingChanged() {
        let firstLoad = waitForState { $0.items.count == 2 && !$0.isLoadingMore }
        viewDidLoadSubject.send(())
        wait(for: [firstLoad], timeout: 2)

        queryChangedSubject.send("   ")
        let settled = expectation(description: "debounce window elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { settled.fulfill() }
        wait(for: [settled], timeout: 2)

        XCTAssertEqual(repository.listCalls.count, 1)
    }

    func test_normalizedQuery_trimsAndCapsAtServerLimit() {
        XCTAssertEqual(ILSutrasViewModel.normalizedQuery("  kinh  "), "kinh")
        XCTAssertEqual(ILSutrasViewModel.normalizedQuery(" \n "), "")
        XCTAssertEqual(ILSutrasViewModel.normalizedQuery(String(repeating: "a", count: 150)).count, 100)
    }

    func test_noResults_showsEmptyCopyOnlyWhenNotLoading() {
        repository.onLoadSutras = { _, _ in ILSutraPageEntity(items: [], page: 1, totalCount: 0, hasMore: false) }
        var states: [ILSutrasStateModel] = []
        let settled = waitForState { states.append($0); return !$0.isLoadingMore && $0.items.isEmpty && states.count > 1 }

        viewDidLoadSubject.send(())
        wait(for: [settled], timeout: 2)

        let loadingState = states.first { $0.isLoadingMore }
        XCTAssertEqual(loadingState?.emptyTitle, "", "No empty copy while the first page is loading")
        XCTAssertEqual(states.last?.emptyTitle, "sutras.empty.title".localized)
    }

    func test_cardModel_mapsTranslatorTraditionPurposesAndMissingDuration() {
        repository.onLoadSutras = { _, _ in
            ILSutraPageEntity(
                items: [
                    ILSutraFixtures.sutra(
                        id: "a", originalTitle: "Maṅgalasutta", tradition: .theravada,
                        isDailyChant: true, purposes: [.blessing], durationMinutes: 4,
                        audioURL: "https://cdn.test/a.mp3"
                    ),
                    ILSutraFixtures.sutra(id: "b", tradition: nil, durationMinutes: nil, translator: "")
                ],
                page: 1, totalCount: 2, hasMore: false
            )
        }
        var latest: ILSutrasStateModel?
        let loaded = waitForState { latest = $0; return $0.items.count == 2 }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)

        let first = latest?.items[0]
        XCTAssertEqual(first?.originalName, "Maṅgalasutta")
        XCTAssertEqual(first?.durationText, String(format: "sutras.duration.minutesFormat".localized, 4))
        XCTAssertEqual(first?.translatorLine, "Thích Minh Châu\("sutras.translatorSeparator".localized)\("sutras.category.theravada".localized)")
        XCTAssertEqual(first?.purposeLabels, ["sutras.category.daily".localized, "sutras.category.blessing".localized])
        XCTAssertEqual(first?.hasAudio, true)
        XCTAssertEqual(first?.isDownloaded, false)

        let second = latest?.items[1]
        XCTAssertEqual(second?.durationText, "")
        XCTAssertEqual(second?.translatorLine, "")
        XCTAssertEqual(second?.hasAudio, false, "An empty audio_url means no audio")
    }

    func test_durationText_formatsMinutesAndHours() {
        XCTAssertEqual(ILSutrasViewModel.durationText(minutes: 22), String(format: "sutras.duration.minutesFormat".localized, 22))
        XCTAssertEqual(ILSutrasViewModel.durationText(minutes: 120), String(format: "sutras.duration.hoursFormat".localized, 2))
        XCTAssertEqual(ILSutrasViewModel.durationText(minutes: 130), String(format: "sutras.duration.hoursMinutesFormat".localized, 2, 10))
    }

    func test_navigation_backAndSutraTapped() {
        var events: [ILSutrasNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        backTappedSubject.send(())
        sutraTappedSubject.send("vu-lan")

        XCTAssertEqual(events, [.back, .openSutra(id: "vu-lan")])
    }
}
