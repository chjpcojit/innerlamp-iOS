//
//  ILFestivalDetailViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILFestivalDetailViewModelTests: XCTestCase {

    private var mockUseCase: MockILFestivalDetailUseCase!
    private var sut: ILFestivalDetailViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var retryTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    private static let stubDate = Calendar(identifier: .gregorian)
        .date(from: DateComponents(year: 2026, month: 8, day: 28))!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILFestivalDetailUseCase()
        mockUseCase.result = Self.makeEntity()
        sut = ILFestivalDetailViewModel(useCase: mockUseCase, eventCode: "vu-lan", date: Self.stubDate)
        cancellables = []
        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        retryTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        retryTappedSubject = nil
        backTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILFestivalDetailViewModel.Input {
        ILFestivalDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    private static func makeEntity(
        longDescription: String = "Đoạn một.\nĐoạn hai.",
        shortDescription: String = "Mô tả ngắn.",
        guidance: String = "- Đi chùa\nTụng kinh",
        imageURL: String? = "https://example.com/vu-lan.jpg",
        groupNames: [String] = ["Phật giáo"],
        daysUntil: Int = 3
    ) -> ILFestivalDetailEntity {
        ILFestivalDetailEntity(
            code: "vu-lan", name: "Đại lễ Vu Lan",
            shortDescription: shortDescription, longDescription: longDescription, guidance: guidance,
            imageURL: imageURL, groupNames: groupNames,
            date: stubDate, lunarDay: 15, lunarMonth: 7, isLeapMonth: false, daysUntil: daysUntil
        )
    }

    // MARK: - Tests

    func test_viewDidLoad_requestsEventAndDate() {
        let output = sut.transform(input: makeInput())
        _ = waitForSuccess(output)

        XCTAssertEqual(mockUseCase.requests.count, 1)
        XCTAssertEqual(mockUseCase.requests.first?.code, "vu-lan")
        XCTAssertEqual(mockUseCase.requests.first?.date, Self.stubDate)
    }

    func test_viewDidLoad_mapsEntityToStateModel() {
        let output = sut.transform(input: makeInput())
        let state = waitForSuccess(output)

        XCTAssertEqual(state?.title, "Đại lễ Vu Lan")
        XCTAssertEqual(state?.kindText, "PHẬT GIÁO")
        XCTAssertEqual(state?.aboutParagraphs, ["Đoạn một.", "Đoạn hai."])
        XCTAssertEqual(state?.practices, ["Đi chùa", "Tụng kinh"])
        XCTAssertEqual(state?.imageURL, "https://example.com/vu-lan.jpg")
        XCTAssertEqual(state?.dayText, "28")
        XCTAssertEqual(state?.countdownText, String(format: "festivalDetail.countdown.days".localized, 3))
    }

    func test_missingContent_keepsSectionsWithEmptyText() {
        mockUseCase.result = Self.makeEntity(
            longDescription: "", shortDescription: "", guidance: "", imageURL: nil, groupNames: []
        )
        let output = sut.transform(input: makeInput())
        let state = waitForSuccess(output)

        XCTAssertEqual(state?.aboutParagraphs, [])
        XCTAssertEqual(state?.practices, [])
        XCTAssertNil(state?.imageURL)
        XCTAssertEqual(state?.kindText, "festivalDetail.kind.empty".localized)
        XCTAssertFalse(state?.aboutEmptyText.isEmpty ?? true)
        XCTAssertFalse(state?.practicesEmptyText.isEmpty ?? true)
        XCTAssertFalse(state?.sutraEmptyText.isEmpty ?? true)
        XCTAssertFalse(state?.hostsEmptyText.isEmpty ?? true)
    }

    func test_emptyLongDescription_fallsBackToShortDescription() {
        mockUseCase.result = Self.makeEntity(longDescription: "", shortDescription: "Mô tả ngắn.")
        let output = sut.transform(input: makeInput())
        let state = waitForSuccess(output)

        XCTAssertEqual(state?.aboutParagraphs, ["Mô tả ngắn."])
    }

    func test_countdown_today_tomorrow_past() {
        for (days, key) in [(0, "festivals.item.countdown.today"), (1, "festivals.item.countdown.tomorrow"), (-2, "festivals.item.countdown.past")] {
            let state = ILFestivalDetailViewModel.makeStateModel(from: Self.makeEntity(daysUntil: days))
            XCTAssertEqual(state.countdownText, key.localized)
        }
    }

    func test_viewDidLoad_failure_emitsFailure_andRetryReloads() {
        mockUseCase.error = ILCatalogError.offline
        let output = sut.transform(input: makeInput())

        let failed = expectation(description: "failure")
        output.state
            .sink { state in
                if case .failure = state { failed.fulfill() }
            }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 1.0)

        mockUseCase.error = nil
        let recovered = expectation(description: "success after retry")
        output.state
            .sink { state in
                if case .success = state { recovered.fulfill() }
            }
            .store(in: &cancellables)
        retryTappedSubject.send(())
        wait(for: [recovered], timeout: 1.0)

        XCTAssertEqual(mockUseCase.requests.count, 2)
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILFestivalDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    // MARK: - Helpers

    @discardableResult
    private func waitForSuccess(_ output: ILFestivalDetailViewModel.Output) -> ILFestivalDetailStateModel? {
        var received: ILFestivalDetailStateModel?
        let succeeded = expectation(description: "state becomes success")
        output.state
            .sink { state in
                if case .success(let model) = state {
                    received = model
                    succeeded.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [succeeded], timeout: 1.0)
        return received
    }
}

// MARK: - Mock ILFestivalDetailUseCase
final class MockILFestivalDetailUseCase: ILFestivalDetailUseCase {
    var result: ILFestivalDetailEntity?
    var error: Error?
    var requests: [(code: String, date: Date)] = []

    func loadDetail(code: String, date: Date, today: Date) async throws -> ILFestivalDetailEntity {
        requests.append((code, date))
        if let error { throw error }
        guard let result else { throw ILCatalogError.notFound }
        return result
    }
}
