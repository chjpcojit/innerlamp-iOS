//
//  ILMeritBookViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

@MainActor
final class ILMeritBookViewModelTests: XCTestCase {

    private var useCase: MockILMeritBookUseCase!
    private var sut: ILMeritBookViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var donateTappedSubject: PassthroughSubject<Void, Never>!
    private var stopMonthlyTappedSubject: PassthroughSubject<Void, Never>!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    override func setUp() {
        super.setUp()
        useCase = MockILMeritBookUseCase(entity: Self.sampleEntity(calendar: calendar))
        sut = ILMeritBookViewModel(
            useCase: useCase,
            calendar: calendar,
            now: { Self.date(2026, 10, 11, calendar: self.calendar) }
        )
        cancellables = []
        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        donateTappedSubject = PassthroughSubject<Void, Never>()
        stopMonthlyTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        donateTappedSubject = nil
        stopMonthlyTappedSubject = nil
        sut = nil
        useCase = nil
        super.tearDown()
    }

    // MARK: - Helpers
    private static func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9)) ?? Date()
    }

    private static func sampleEntity(calendar: Calendar) -> ILMeritBookEntity {
        ILMeritBookEntity(
            offerings: [
                ILMeritOfferingEntity(
                    id: "old", date: date(2025, 11, 12, calendar: calendar), purpose: .charityKitchen,
                    templeName: "Chùa B", amount: 200_000, isConfirmedByTemple: true
                ),
                ILMeritOfferingEntity(
                    id: "lamp", date: date(2026, 8, 15, calendar: calendar), purpose: .templeLamp,
                    templeName: "Chùa A", amount: 100_000, isConfirmedByTemple: false
                ),
                ILMeritOfferingEntity(
                    id: "jewels", date: date(2026, 9, 2, calendar: calendar), purpose: .threeJewels,
                    templeName: "Chùa A", amount: 1_100_000, isConfirmedByTemple: true
                )
            ],
            letter: ILMeritLetterEntity(body: "Thư", signerName: "Đại đức A", signerTitle: "Trụ trì"),
            monthlySupport: ILMeritMonthlySupportEntity(amount: 100_000, templeName: "Chùa A"),
            buildProject: ILMeritBuildProjectEntity(
                name: "Trùng tu", subtitle: "Chùa A · đợt 2", raisedMillions: 412, goalMillions: 600,
                updatedAt: date(2026, 10, 1, calendar: calendar),
                expenses: [.init(label: "Ngói", amount: 128_000_000)]
            )
        )
    }

    private func makeInput() -> ILMeritBookViewModel.Input {
        ILMeritBookViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            donateTapped: donateTappedSubject.eraseToAnyPublisher(),
            stopMonthlyTapped: stopMonthlyTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureStates(_ output: ILMeritBookViewModel.Output) -> () -> [ViewState<ILMeritBookStateModel>] {
        var states: [ViewState<ILMeritBookStateModel>] = []
        output.state
            .sink { states.append($0) }
            .store(in: &cancellables)
        return { states }
    }

    private func latestModel(_ states: [ViewState<ILMeritBookStateModel>]) -> ILMeritBookStateModel? {
        for state in states.reversed() {
            if case .success(let model) = state { return model }
        }
        return nil
    }

    private func awaitSuccess(_ output: ILMeritBookViewModel.Output) async -> ILMeritBookStateModel? {
        for await state in output.state.values {
            if case .success(let model) = state { return model }
            if case .failure = state { return nil }
        }
        return nil
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_emitsLoadingThenMapsStateModel() async {
        let output = sut.transform(input: makeInput())
        let states = captureStates(output)

        viewDidLoadSubject.send(())
        let model = await awaitSuccess(output)

        guard case .loading = states().dropFirst().first else {
            return XCTFail("expected .loading right after viewDidLoad, got \(states())")
        }
        XCTAssertEqual(useCase.getMeritBookCallCount, 1)
        XCTAssertEqual(model?.history.map(\.id), ["jewels", "lamp", "old"]) // newest first
        XCTAssertEqual(model?.history.first?.amount, "1.100.000đ")
        XCTAssertEqual(model?.history.first?.subtitle, "Chùa A · 02/09/2026")
        XCTAssertEqual(model?.history.first?.isConfirmed, true)
        XCTAssertEqual(model?.history[1].isConfirmed, false)
        XCTAssertEqual(model?.letter?.body, "Thư")
        XCTAssertNotNil(model?.monthly)
        XCTAssertEqual(model?.buildProject?.percentText, "69%")
        XCTAssertEqual(model?.buildProject?.lines.first?.value, "128.000.000đ")
        XCTAssertEqual(model?.buildProject?.progress ?? 0, 412.0 / 600.0, accuracy: 0.0001)
    }

    func test_viewDidLoad_statsCountThisYearLampsAndDistinctTemples() async {
        let output = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        let model = await awaitSuccess(output)

        // 2026 only: 100.000 + 1.100.000 = 1.200.000 → "1,2 tr"
        XCTAssertEqual(model?.stats.map(\.value), [ILMeritBookViewModel.compactAmount(1_200_000), "1", "2"])
    }

    func test_viewDidLoad_failure_emitsFailure() async {
        useCase.error = URLError(.notConnectedToInternet)
        let output = sut.transform(input: makeInput())
        let states = captureStates(output)

        viewDidLoadSubject.send(())
        _ = await awaitSuccess(output)

        guard case .failure = states().last else {
            return XCTFail("expected .failure, got \(states())")
        }
    }

    func test_viewDidLoad_withoutOptionalBlocks_hidesThem() async {
        useCase.entity = ILMeritBookEntity(offerings: [], letter: nil, monthlySupport: nil, buildProject: nil)
        let output = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        let model = await awaitSuccess(output)

        XCTAssertEqual(model?.history, [])
        XCTAssertNil(model?.letter)
        XCTAssertNil(model?.monthly)
        XCTAssertNil(model?.buildProject)
        XCTAssertEqual(model?.stats.map(\.value), ["0", "0", "0"])
    }

    // MARK: - Stop monthly
    func test_stopMonthlyTapped_stopsAndClearsMonthly() async {
        let output = sut.transform(input: makeInput())
        let states = captureStates(output)
        viewDidLoadSubject.send(())
        _ = await awaitSuccess(output)

        stopMonthlyTappedSubject.send(())
        for _ in 0..<50 where latestModel(states())?.monthly != nil {
            await Task.yield()
        }

        XCTAssertEqual(useCase.stopMonthlyCallCount, 1)
        XCTAssertNil(latestModel(states())?.monthly)
    }

    func test_stopMonthlyTapped_withoutActiveSupport_isNoOp() async {
        useCase.entity = ILMeritBookEntity(offerings: [], letter: nil, monthlySupport: nil, buildProject: nil)
        let output = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        _ = await awaitSuccess(output)

        stopMonthlyTappedSubject.send(())
        await Task.yield()

        XCTAssertEqual(useCase.stopMonthlyCallCount, 0)
    }

    // MARK: - Navigation
    func test_backTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        var events: [ILMeritBookNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(events, [.goBack])
    }

    func test_donateTapped_firesOpenDonate() {
        _ = sut.transform(input: makeInput())
        var events: [ILMeritBookNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        donateTappedSubject.send(())

        XCTAssertEqual(events, [.openDonate])
    }

    // MARK: - Formatting helpers
    func test_money_groupsThousandsWithDots() {
        XCTAssertEqual(ILMeritBookViewModel.money(0), "0đ")
        XCTAssertEqual(ILMeritBookViewModel.money(50_000), "50.000đ")
        XCTAssertEqual(ILMeritBookViewModel.money(1_234_567), "1.234.567đ")
    }

    func test_compactAmount_usesMillionsThousandsOrPlain() {
        XCTAssertEqual(ILMeritBookViewModel.compactAmount(999), "999")
        XCTAssertEqual(ILMeritBookViewModel.compactAmount(300_000), "300k")
        XCTAssertEqual(
            ILMeritBookViewModel.compactAmount(1_100_000),
            String(format: "meritBook.stats.millionFormat".localized, "1,1")
        )
        XCTAssertEqual(
            ILMeritBookViewModel.compactAmount(2_000_000),
            String(format: "meritBook.stats.millionFormat".localized, "2")
        )
    }
}

// MARK: - Mock
final class MockILMeritBookUseCase: ILMeritBookUseCase {
    var entity: ILMeritBookEntity
    var error: Error?
    private(set) var getMeritBookCallCount = 0
    private(set) var stopMonthlyCallCount = 0

    init(entity: ILMeritBookEntity) {
        self.entity = entity
    }

    func getMeritBook() async throws -> ILMeritBookEntity {
        getMeritBookCallCount += 1
        if let error { throw error }
        return entity
    }

    func stopMonthlySupport() async throws {
        stopMonthlyCallCount += 1
        if let error { throw error }
    }
}
