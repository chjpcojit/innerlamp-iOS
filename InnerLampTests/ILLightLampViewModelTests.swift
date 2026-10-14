//
//  ILLightLampViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLightLampViewModelTests: XCTestCase {

    private var mockUseCase: MockILLightLampUseCase!
    private var sut: ILLightLampViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var gardenTappedSubject: PassthroughSubject<Void, Never>!
    private var kindSelectedSubject: PassthroughSubject<ILLampKind, Never>!
    private var intentionSelectedSubject: PassthroughSubject<ILLampIntention, Never>!
    private var durationSelectedSubject: PassthroughSubject<Int, Never>!
    private var targetChangedSubject: PassthroughSubject<String, Never>!
    private var vowChangedSubject: PassthroughSubject<String, Never>!
    private var lightTappedSubject: PassthroughSubject<Void, Never>!
    private var againTappedSubject: PassthroughSubject<Void, Never>!

    private var latestModel: ILLightLampStateModel?
    private var failureCount = 0
    /// Called on every emitted model; `waitFor` uses it to resume once a condition holds.
    private var modelObserver: ((ILLightLampStateModel) -> Void)?

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLightLampUseCase()
        // No ignition delay: the tests only care about the state sequence, not the 2.1 s animation.
        sut = ILLightLampViewModel(
            useCase: mockUseCase,
            now: { ILLightLampTestFactory.date(2026, 10, 11) },
            igniteDelay: .zero
        )
        cancellables = []
        viewDidLoadSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        gardenTappedSubject = PassthroughSubject()
        kindSelectedSubject = PassthroughSubject()
        intentionSelectedSubject = PassthroughSubject()
        durationSelectedSubject = PassthroughSubject()
        targetChangedSubject = PassthroughSubject()
        vowChangedSubject = PassthroughSubject()
        lightTappedSubject = PassthroughSubject()
        againTappedSubject = PassthroughSubject()
        latestModel = nil
        failureCount = 0

        let output = sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            gardenTapped: gardenTappedSubject.eraseToAnyPublisher(),
            kindSelected: kindSelectedSubject.eraseToAnyPublisher(),
            intentionSelected: intentionSelectedSubject.eraseToAnyPublisher(),
            durationSelected: durationSelectedSubject.eraseToAnyPublisher(),
            targetChanged: targetChangedSubject.eraseToAnyPublisher(),
            vowChanged: vowChangedSubject.eraseToAnyPublisher(),
            lightTapped: lightTappedSubject.eraseToAnyPublisher(),
            againTapped: againTappedSubject.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                switch state {
                case .success(let model):
                    self?.latestModel = model
                    self?.modelObserver?(model)
                case .failure: self?.failureCount += 1
                case .idle, .loading: break
                }
            }
            .store(in: &cancellables)
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    /// Waits until an emitted model (or the latest one already emitted) satisfies `predicate`.
    private func waitFor(_ description: String, _ predicate: @escaping (ILLightLampStateModel) -> Bool) {
        if let latestModel, predicate(latestModel) { return }
        let expectation = expectation(description: description)
        modelObserver = { model in
            if predicate(model) {
                expectation.fulfill()
                self.modelObserver = nil
            }
        }
        wait(for: [expectation], timeout: 1)
        modelObserver = nil
    }

    // MARK: - Initial state

    func test_initialState_hasDefaultSelections() {
        let model = latestModel

        XCTAssertEqual(model?.phase, .form)
        XCTAssertEqual(model?.selectedKind, .oil)
        XCTAssertEqual(model?.kinds.first(where: \.isSelected)?.kind, .oil)
        XCTAssertEqual(model?.intentions.first(where: \.isSelected)?.intention, .peace)
        XCTAssertEqual(model?.selectedDurationIndex, ILLampEntity.durationOptions.firstIndex(of: 7))
        XCTAssertEqual(model?.countLine, "lightLamp.stage.count.none".localized)
    }

    // MARK: - Selection

    func test_kindSelected_updatesSelectionAndKicker() {
        kindSelectedSubject.send(.float)

        XCTAssertEqual(latestModel?.selectedKind, .float)
        XCTAssertEqual(latestModel?.kinds.first(where: \.isSelected)?.kind, .float)
        XCTAssertTrue(latestModel?.kicker.contains("HOA ĐĂNG") ?? false)
    }

    func test_durationSelected_updatesSelectedIndex() {
        durationSelectedSubject.send(49)

        XCTAssertEqual(latestModel?.selectedDurationIndex, ILLampEntity.durationOptions.firstIndex(of: 49))
    }

    func test_intentionSelected_updatesSelection() {
        intentionSelectedSubject.send(.departed)

        XCTAssertEqual(latestModel?.intentions.first(where: \.isSelected)?.intention, .departed)
    }

    // MARK: - Lighting

    func test_lightTapped_movesToLightingThenDone() {
        targetChangedSubject.send("Mẹ")
        vowChangedSubject.send("Mẹ luôn khỏe")

        lightTappedSubject.send(())
        XCTAssertEqual(latestModel?.phase, .lighting)
        XCTAssertEqual(latestModel?.buttonTitle, "lightLamp.button.lighting".localized)

        waitFor("done") { $0.phase == .done }
        XCTAssertEqual(mockUseCase.lightedDrafts.count, 1)
        XCTAssertEqual(
            latestModel?.completion?.dedication,
            String(format: "lightLamp.done.dedication.target".localized, "Mẹ")
        )
        XCTAssertEqual(latestModel?.completion?.vowQuote, "“Mẹ luôn khỏe”")
    }

    func test_lightTapped_emptyTarget_dedicatesToAllBeings() {
        lightTappedSubject.send(())

        waitFor("done") { $0.phase == .done }
        XCTAssertEqual(latestModel?.completion?.dedication, "lightLamp.done.dedication.all".localized)
        XCTAssertEqual(latestModel?.completion?.vowQuote, "")
    }

    func test_lightTapped_twice_savesOnlyOneLamp() {
        lightTappedSubject.send(())
        lightTappedSubject.send(())

        waitFor("done") { $0.phase == .done }
        XCTAssertEqual(mockUseCase.lightedDrafts.count, 1)
    }

    func test_lightTapped_saveFails_returnsToFormKeepingValues() {
        mockUseCase.lightError = ILLightLampTestError()
        targetChangedSubject.send("Ba")

        lightTappedSubject.send(())

        waitFor("back to form") { $0.phase == .form && $0.target == "Ba" }
        XCTAssertEqual(failureCount, 1)
        XCTAssertNil(latestModel?.completion)
    }

    // MARK: - Light another

    func test_againTapped_clearsTargetAndVowButKeepsChoices() {
        kindSelectedSubject.send(.lotus)
        durationSelectedSubject.send(21)
        targetChangedSubject.send("Ba")
        vowChangedSubject.send("Bình an")
        lightTappedSubject.send(())
        waitFor("done") { $0.phase == .done }

        againTappedSubject.send(())

        XCTAssertEqual(latestModel?.phase, .form)
        XCTAssertEqual(latestModel?.target, "")
        XCTAssertEqual(latestModel?.vow, "")
        XCTAssertEqual(latestModel?.selectedKind, .lotus)
        XCTAssertEqual(latestModel?.selectedDurationIndex, ILLampEntity.durationOptions.firstIndex(of: 21))
    }

    // MARK: - Navigation

    func test_gardenTapped_firesOpenGarden() {
        var event: ILLightLampNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        gardenTappedSubject.send(())

        XCTAssertEqual(event, .openGarden)
    }

    func test_backTapped_firesBack() {
        var event: ILLightLampNavEvent?
        sut.navigationEventPublisher.sink { event = $0 }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(event, .back)
    }

    // MARK: - Count line

    func test_viewDidLoad_withActiveLamps_showsCountLine() {
        mockUseCase.activeLamps = [
            ILLightLampTestFactory.lamp(id: "a", litAt: ILLightLampTestFactory.date(2026, 10, 11)),
            ILLightLampTestFactory.lamp(id: "b", litAt: ILLightLampTestFactory.date(2026, 10, 11))
        ]

        viewDidLoadSubject.send(())

        waitFor("count line") { $0.countLine == String(format: "lightLamp.stage.count.format".localized, 2) }
    }
}
