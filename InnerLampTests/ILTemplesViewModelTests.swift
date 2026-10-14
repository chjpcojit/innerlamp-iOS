//
//  ILTemplesViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

private final class MockILTemplesUseCase: ILTemplesUseCase {
    var result: Result<[ILTempleSummaryEntity], Error> = .success(MockILTempleFinderUseCase.defaultTemples)
    func loadTemples() async throws -> [ILTempleSummaryEntity] { try result.get() }
}

final class ILTemplesViewModelTests: XCTestCase {

    private var useCase: MockILTemplesUseCase!
    private var sut: ILTemplesViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var latestState: ViewState<ILTemplesStateModel> = .idle
    private var latestEmpty: (title: String, message: String)?

    private let viewDidLoad = PassthroughSubject<Void, Never>()
    private let back = PassthroughSubject<Void, Never>()
    private let query = PassthroughSubject<String, Never>()
    private let region = PassthroughSubject<ILTempleFinderRegionFilter, Never>()
    private let tapped = PassthroughSubject<String, Never>()
    private let retry = PassthroughSubject<Void, Never>()

    override func setUp() {
        super.setUp()
        useCase = MockILTemplesUseCase()
        sut = ILTemplesViewModel(useCase: useCase)
        cancellables = []
        latestState = .idle
        latestEmpty = nil
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        useCase = nil
        super.tearDown()
    }

    private func load() {
        let loaded = expectation(description: "load settled")
        loaded.assertForOverFulfill = false
        let output = sut.transform(input: .init(
            viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
            backTapped: back.eraseToAnyPublisher(),
            queryChanged: query.eraseToAnyPublisher(),
            regionSelected: region.eraseToAnyPublisher(),
            templeTapped: tapped.eraseToAnyPublisher(),
            retryTapped: retry.eraseToAnyPublisher()
        ))
        output.state.sink { [weak self] state in
            self?.latestState = state
            switch state {
            case .success, .failure: loaded.fulfill()
            default: break
            }
        }.store(in: &cancellables)
        output.emptyText.sink { [weak self] in self?.latestEmpty = $0 }.store(in: &cancellables)
        viewDidLoad.send(())
        wait(for: [loaded], timeout: 2)
    }

    private var rows: [ILTemplesRowModel] {
        if case .success(let model) = latestState { return model.rows }
        return []
    }

    func test_load_showsAllTemplesAndTotalSubtitle() {
        load()
        XCTAssertEqual(rows.map(\.id), ["tq", "vn", "mc"])
        guard case .success(let model) = latestState else { return XCTFail("expected success") }
        XCTAssertEqual(model.subtitle, "3 ngôi chùa")
        XCTAssertNil(latestEmpty)
    }

    func test_query_isDiacriticInsensitive() {
        load()
        query.send("tu quang")
        XCTAssertEqual(rows.map(\.id), ["tq"])
    }

    func test_regionFilter_narrowsList_andSubtitleKeepsTotal() {
        load()
        region.send(.north)
        XCTAssertEqual(rows.map(\.id), ["mc"])
        guard case .success(let model) = latestState else { return XCTFail("expected success") }
        XCTAssertEqual(model.subtitle, "3 ngôi chùa")
    }

    func test_noMatch_publishesEmptyText() {
        load()
        query.send("zzz")
        XCTAssertTrue(rows.isEmpty)
        XCTAssertNotNil(latestEmpty)
    }

    func test_templeTapped_emitsOpenTemple() {
        var events: [ILTemplesNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)
        load()
        tapped.send("vn")
        back.send(())
        XCTAssertEqual(events, [.openTemple(id: "vn"), .back])
    }

    func test_loadFailure_publishesFailure() {
        useCase.result = .failure(ILCatalogError.offline)
        load()
        guard case .failure = latestState else { return XCTFail("expected failure") }
    }
}
