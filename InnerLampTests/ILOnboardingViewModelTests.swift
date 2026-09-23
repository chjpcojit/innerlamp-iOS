//
//  ILOnboardingViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 12/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILOnboardingViewModelTests: XCTestCase {

    private var mockUseCase: MockILOnboardingUseCase!
    private var sut: ILOnboardingViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var nextTriggerSubject: PassthroughSubject<Void, Never>!
    private var backTriggerSubject: PassthroughSubject<Void, Never>!
    private var skipTriggerSubject: PassthroughSubject<Void, Never>!
    private var toggleItemSubject: PassthroughSubject<(stepIndex: Int, itemIndex: Int), Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILOnboardingUseCase()
        sut = ILOnboardingViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        nextTriggerSubject = PassthroughSubject<Void, Never>()
        backTriggerSubject = PassthroughSubject<Void, Never>()
        skipTriggerSubject = PassthroughSubject<Void, Never>()
        toggleItemSubject = PassthroughSubject<(stepIndex: Int, itemIndex: Int), Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        nextTriggerSubject = nil
        backTriggerSubject = nil
        skipTriggerSubject = nil
        toggleItemSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeOutput() -> ILOnboardingViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            nextTrigger: nextTriggerSubject.eraseToAnyPublisher(),
            backTrigger: backTriggerSubject.eraseToAnyPublisher(),
            skipTrigger: skipTriggerSubject.eraseToAnyPublisher(),
            toggleItem: toggleItemSubject.eraseToAnyPublisher()
        ))
    }

    func test_initialState_loadsStep0WithDefaults() {
        let output = makeOutput()
        var receivedState: ILOnboardingStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.currentStep, 0)
        XCTAssertEqual(receivedState?.ctaTitle, "Bắt đầu")
        XCTAssertEqual(receivedState?.backTitle, "Tôi đã có tài khoản")
        XCTAssertEqual(receivedState?.intents.count, 6)
        XCTAssertEqual(receivedState?.bells.count, 3)
    }

    func test_nextStep_advancesThroughAllStepsAndCompletes() {
        let output = makeOutput()
        var receivedState: ILOnboardingStateModel?
        var receivedNavEvent: ILOnboardingNavEvent?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { receivedNavEvent = $0 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        // Step 0 -> Step 1
        nextTriggerSubject.send(())
        XCTAssertEqual(receivedState?.currentStep, 1)
        XCTAssertEqual(receivedState?.ctaTitle, "Tiếp tục")
        XCTAssertEqual(receivedState?.backTitle, "Quay lại")

        // Step 1 -> Step 2
        nextTriggerSubject.send(())
        XCTAssertEqual(receivedState?.currentStep, 2)
        XCTAssertEqual(receivedState?.ctaTitle, "Tạo tài khoản")
        XCTAssertTrue(receivedState?.isLastStep == true)

        // Step 2 -> Finish (Navigate to Signup)
        nextTriggerSubject.send(())

        XCTAssertEqual(receivedNavEvent, .goToSignup)
        XCTAssertTrue(mockUseCase.savePreferencesCalled)
        XCTAssertTrue(mockUseCase.markOnboardingCompletedCalled)
    }

    func test_backStep_fromStep0_navigatesToLogin() {
        let output = makeOutput()
        var receivedNavEvent: ILOnboardingNavEvent?
        output.state.sink { _ in }.store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { receivedNavEvent = $0 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        backTriggerSubject.send(())

        XCTAssertEqual(receivedNavEvent, .goToLogin)
    }

    func test_backStep_fromStep2_returnsToStep1() {
        let output = makeOutput()
        var receivedState: ILOnboardingStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        // Advance to step 2
        nextTriggerSubject.send(())
        nextTriggerSubject.send(())

        // Back to step 1
        backTriggerSubject.send(())

        XCTAssertEqual(receivedState?.currentStep, 1)
    }

    func test_skip_marksCompletedAndNavigatesToSignup() {
        let output = makeOutput()
        var receivedNavEvent: ILOnboardingNavEvent?
        output.state.sink { _ in }.store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { receivedNavEvent = $0 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        skipTriggerSubject.send(())

        XCTAssertEqual(receivedNavEvent, .goToSignup)
        XCTAssertTrue(mockUseCase.markOnboardingCompletedCalled)
    }

    func test_toggleIntent_togglesSelection() {
        let output = makeOutput()
        var receivedState: ILOnboardingStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        // Step 1 = chipChoice(intents)
        toggleItemSubject.send((stepIndex: 1, itemIndex: 1))
        XCTAssertEqual(receivedState?.intents[1].isSelected, true)

        toggleItemSubject.send((stepIndex: 1, itemIndex: 1))
        XCTAssertEqual(receivedState?.intents[1].isSelected, false)
    }

    func test_toggleBell_togglesEnabled() {
        let output = makeOutput()
        var receivedState: ILOnboardingStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        // Default is true
        XCTAssertEqual(receivedState?.bells[0].isEnabled, true)

        // Step 2 = toggleList(bells)
        toggleItemSubject.send((stepIndex: 2, itemIndex: 0))
        XCTAssertEqual(receivedState?.bells[0].isEnabled, false)
    }
}

// MARK: - Mock ILOnboardingUseCase
final class MockILOnboardingUseCase: ILOnboardingUseCase {
    var savePreferencesCalled = false
    var markOnboardingCompletedCalled = false
    var savedState: ILOnboardingStateModel?
    var isCompleted = false

    func getInitialState() -> ILOnboardingStateModel {
        return ILOnboardingStateModel.initial
    }

    func savePreferences(state: ILOnboardingStateModel) {
        savePreferencesCalled = true
        savedState = state
        markOnboardingCompleted()
    }

    func markOnboardingCompleted() {
        markOnboardingCompletedCalled = true
        isCompleted = true
    }

    func isOnboardingCompleted() -> Bool {
        return isCompleted
    }
}
