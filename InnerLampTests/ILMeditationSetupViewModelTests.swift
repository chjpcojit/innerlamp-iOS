//
//  ILMeditationSetupViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 26/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMeditationSetupViewModelTests: XCTestCase {

    private var mockUseCase: MockILMeditationSetupUseCase!
    private var sut: ILMeditationSetupViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var durationSelectedSubject: PassthroughSubject<Int, Never>!
    private var startTappedSubject: PassthroughSubject<Void, Never>!
    private var silentTappedSubject: PassthroughSubject<Void, Never>!
    private var closeTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMeditationSetupUseCase()
        sut = ILMeditationSetupViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        durationSelectedSubject = PassthroughSubject<Int, Never>()
        startTappedSubject = PassthroughSubject<Void, Never>()
        silentTappedSubject = PassthroughSubject<Void, Never>()
        closeTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        durationSelectedSubject = nil
        startTappedSubject = nil
        silentTappedSubject = nil
        closeTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILMeditationSetupViewModel.Input {
        ILMeditationSetupViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            durationSelected: durationSelectedSubject.eraseToAnyPublisher(),
            startTapped: startTappedSubject.eraseToAnyPublisher(),
            silentTapped: silentTappedSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeState(_ output: ILMeditationSetupViewModel.Output) -> StateBox {
        let box = StateBox()
        output.state
            .sink { state in
                if case .success(let model) = state { box.latest = model }
            }
            .store(in: &cancellables)
        return box
    }

    func test_initialState_matchesUseCaseDefaultAndStaticLabels() {
        mockUseCase.stubEntity = ILMeditationSetupEntity(durationOptions: [5, 12, 20, 30, 45], durationMinutes: 20)
        sut = ILMeditationSetupViewModel(useCase: mockUseCase)
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(box.latest?.durationOptions, [5, 12, 20, 30, 45])
        XCTAssertEqual(box.latest?.selectedDurationIndex, 2)
        XCTAssertEqual(box.latest?.headerTitle, "meditationSetup.header.title".localized)
        XCTAssertEqual(box.latest?.title, "meditationSetup.title".localized)
        XCTAssertEqual(box.latest?.startButtonTitle, String(format: "meditationSetup.cta.startFormat".localized, 20))
        XCTAssertEqual(box.latest?.silentButtonTitle, "meditationSetup.cta.silent".localized)
    }

    func test_durationSelected_updatesDurationAndFormatsStartButton() {
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        durationSelectedSubject.send(30)

        XCTAssertTrue(mockUseCase.selectDurationCalled)
        XCTAssertEqual(mockUseCase.lastSelectedMinutes, 30)
        XCTAssertEqual(box.latest?.selectedDurationIndex, 3)
        XCTAssertEqual(box.latest?.startButtonTitle, String(format: "meditationSetup.cta.startFormat".localized, 30))
    }

    func test_startTapped_firesGuidedSessionEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationSetupNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        startTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .startSession(durationMinutes: 20, guided: true))
    }

    func test_silentTapped_firesSilentSessionEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationSetupNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        silentTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .startSession(durationMinutes: 20, guided: false))
    }

    func test_startTapped_afterSelectingDuration_carriesSelectedDuration() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationSetupNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        durationSelectedSubject.send(45)
        startTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .startSession(durationMinutes: 45, guided: true))
    }

    func test_closeTapped_firesCloseEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationSetupNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        closeTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .close)
    }
}

// MARK: - ILMeditationSetupUseCaseImpl (real domain rules)
final class ILMeditationSetupUseCaseTests: XCTestCase {

    private let sut = ILMeditationSetupUseCaseImpl()

    func test_getInitialState_returnsDefaultTwentyMinutes() {
        let entity = sut.getInitialState()
        XCTAssertEqual(entity.durationOptions, [5, 12, 20, 30, 45])
        XCTAssertEqual(entity.durationMinutes, 20)
    }

    func test_selectDuration_validOption_updatesDurationMinutes() {
        let entity = ILMeditationSetupEntity(durationOptions: [5, 12, 20, 30, 45], durationMinutes: 20)
        let result = sut.selectDuration(30, in: entity)
        XCTAssertEqual(result.durationMinutes, 30)
        XCTAssertEqual(result.durationOptions, entity.durationOptions)
    }

    func test_selectDuration_invalidOption_keepsCurrentDuration() {
        let entity = ILMeditationSetupEntity(durationOptions: [5, 12, 20, 30, 45], durationMinutes: 20)
        let result = sut.selectDuration(99, in: entity)
        XCTAssertEqual(result.durationMinutes, 20)
    }

    func test_selectDuration_doesNotMutateOriginalEntity() {
        let entity = ILMeditationSetupEntity(durationOptions: [5, 12, 20, 30, 45], durationMinutes: 20)
        _ = sut.selectDuration(45, in: entity)
        XCTAssertEqual(entity.durationMinutes, 20)
    }
}

// MARK: - Helpers
private final class StateBox {
    var latest: ILMeditationSetupStateModel?
}

// MARK: - Mock ILMeditationSetupUseCase
final class MockILMeditationSetupUseCase: ILMeditationSetupUseCase {
    var stubEntity = ILMeditationSetupEntity()

    var getInitialStateCalled = false
    func getInitialState() -> ILMeditationSetupEntity {
        getInitialStateCalled = true
        return stubEntity
    }

    var selectDurationCalled = false
    var lastSelectedMinutes: Int?
    func selectDuration(_ minutes: Int, in entity: ILMeditationSetupEntity) -> ILMeditationSetupEntity {
        selectDurationCalled = true
        lastSelectedMinutes = minutes
        var newEntity = entity
        newEntity.durationMinutes = minutes
        return newEntity
    }
}
