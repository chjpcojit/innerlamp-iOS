//
//  ILMalaViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMalaViewModelTests: XCTestCase {

    private var mockUseCase: MockILMalaUseCase!
    private var mockSoundPlayer: MockILPracticeSoundPlayer!
    private var sut: ILMalaViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var beadAdvancedSubject: PassthroughSubject<Void, Never>!
    private var resetTappedSubject: PassthroughSubject<Void, Never>!
    private var doneTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMalaUseCase()
        mockSoundPlayer = MockILPracticeSoundPlayer()
        sut = ILMalaViewModel(useCase: mockUseCase, soundPlayer: mockSoundPlayer)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        beadAdvancedSubject = PassthroughSubject<Void, Never>()
        resetTappedSubject = PassthroughSubject<Void, Never>()
        doneTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        beadAdvancedSubject = nil
        resetTappedSubject = nil
        doneTappedSubject = nil
        backTappedSubject = nil
        sut = nil
        mockUseCase = nil
        mockSoundPlayer = nil
        super.tearDown()
    }

    private func makeInput() -> ILMalaViewModel.Input {
        ILMalaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            beadAdvanced: beadAdvancedSubject.eraseToAnyPublisher(),
            resetTapped: resetTappedSubject.eraseToAnyPublisher(),
            doneTapped: doneTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribes to `output.state` and returns a box holding the latest success model.
    private func observeState(_ output: ILMalaViewModel.Output) -> StateBox {
        let box = StateBox()
        output.state
            .sink { state in
                if case .success(let model) = state { box.latest = model }
            }
            .store(in: &cancellables)
        return box
    }

    func test_initialState_matchesUseCaseDefaultAndStaticLabels() {
        mockUseCase.stubEntity = ILMalaEntity(count: 27, goal: 108, completedRounds: 2)
        sut = ILMalaViewModel(useCase: mockUseCase, soundPlayer: mockSoundPlayer)
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(box.latest?.count, 27)
        XCTAssertEqual(box.latest?.goal, 108)
        XCTAssertEqual(box.latest?.headerTitle, "mala.header.title".localized)
        XCTAssertEqual(box.latest?.headerSubtitle, String(format: "mala.header.roundsFormat".localized, 2))
        XCTAssertEqual(box.latest?.goalText, String(format: "mala.count.goalFormat".localized, 108))
        XCTAssertEqual(box.latest?.mantraText, "mala.mantra".localized)
        XCTAssertNil(box.latest?.milestone)
    }

    func test_beadAdvanced_incrementsCountThroughUseCase() {
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        beadAdvancedSubject.send(())

        XCTAssertTrue(mockUseCase.advanceBeadCalled)
        XCTAssertTrue(mockSoundPlayer.playBeadCalled)
        XCTAssertEqual(box.latest?.count, 1)
        XCTAssertNil(box.latest?.milestone)
    }

    func test_beadAdvanced_atMilestone_exposesMilestoneInState() {
        mockUseCase.stubMilestone = .quarter
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        beadAdvancedSubject.send(())

        XCTAssertEqual(box.latest?.milestone, .quarter)
    }

    func test_beadAdvanced_completingRound_updatesHeaderSubtitle() {
        mockUseCase.stubEntity = ILMalaEntity(count: 107, goal: 108, completedRounds: 2)
        mockUseCase.stubMilestone = .roundComplete
        sut = ILMalaViewModel(useCase: mockUseCase, soundPlayer: mockSoundPlayer)
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        beadAdvancedSubject.send(())

        XCTAssertEqual(box.latest?.count, 108)
        XCTAssertEqual(box.latest?.headerSubtitle, String(format: "mala.header.roundsFormat".localized, 3))
        XCTAssertEqual(box.latest?.milestone, .roundComplete)
        XCTAssertTrue(mockSoundPlayer.playBeadCalled)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
    }

    func test_resetTapped_resetsCountAndClearsMilestone() {
        mockUseCase.stubMilestone = .quarter
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        beadAdvancedSubject.send(())
        resetTappedSubject.send(())

        XCTAssertTrue(mockUseCase.resetBeadsCalled)
        XCTAssertEqual(box.latest?.count, 0)
        XCTAssertNil(box.latest?.milestone)
    }

    func test_doneTapped_firesGoBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMalaNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        doneTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_backTapped_firesGoBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMalaNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }
}

// MARK: - ILMalaUseCaseImpl (real domain rules)
final class ILMalaUseCaseTests: XCTestCase {

    private let sut = ILMalaUseCaseImpl()

    func test_advanceBead_incrementsCount() {
        let result = sut.advanceBead(ILMalaEntity(count: 5, goal: 108, completedRounds: 0))
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result.completedRounds, 0)
    }

    func test_advanceBead_reachingGoal_completesRound() {
        let result = sut.advanceBead(ILMalaEntity(count: 107, goal: 108, completedRounds: 2))
        XCTAssertEqual(result.count, 108)
        XCTAssertEqual(result.completedRounds, 3)
    }

    func test_advanceBead_pastGoal_startsNewRoundAtOne() {
        let result = sut.advanceBead(ILMalaEntity(count: 108, goal: 108, completedRounds: 3))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.completedRounds, 3)
    }

    func test_resetBeads_zeroesCountButKeepsCompletedRounds() {
        let result = sut.resetBeads(ILMalaEntity(count: 60, goal: 108, completedRounds: 4))
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(result.completedRounds, 4)
    }

    func test_milestone_atQuarters_isQuarter() {
        for count in [27, 54, 81] {
            XCTAssertEqual(sut.milestone(for: ILMalaEntity(count: count, goal: 108)), .quarter, "count \(count)")
        }
    }

    func test_milestone_atGoal_isRoundComplete() {
        XCTAssertEqual(sut.milestone(for: ILMalaEntity(count: 108, goal: 108)), .roundComplete)
    }

    func test_milestone_elsewhere_isNil() {
        for count in [0, 1, 26, 28, 107] {
            XCTAssertNil(sut.milestone(for: ILMalaEntity(count: count, goal: 108)), "count \(count)")
        }
    }
}

// MARK: - Helpers
private final class StateBox {
    var latest: ILMalaStateModel?
}

// MARK: - Mock ILMalaUseCase
final class MockILMalaUseCase: ILMalaUseCase {
    var stubEntity = ILMalaEntity()
    var stubMilestone: ILMalaMilestone?

    var getInitialStateCalled = false
    func getInitialState() -> ILMalaEntity {
        getInitialStateCalled = true
        return stubEntity
    }

    var advanceBeadCalled = false
    func advanceBead(_ entity: ILMalaEntity) -> ILMalaEntity {
        advanceBeadCalled = true
        var newEntity = entity
        newEntity.count += 1
        if newEntity.count == entity.goal { newEntity.completedRounds += 1 }
        return newEntity
    }

    var resetBeadsCalled = false
    func resetBeads(_ entity: ILMalaEntity) -> ILMalaEntity {
        resetBeadsCalled = true
        var newEntity = entity
        newEntity.count = 0
        return newEntity
    }

    func milestone(for entity: ILMalaEntity) -> ILMalaMilestone? {
        stubMilestone
    }
}
