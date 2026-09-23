//
//  ILForgotPasswordViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILForgotPasswordViewModelTests: XCTestCase {

    private var mockUseCase: MockILForgotPasswordUseCase!
    private var sut: ILForgotPasswordViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var methodChangedSubject: PassthroughSubject<ILForgotPasswordMethod, Never>!
    private var phoneChangedSubject: PassthroughSubject<String, Never>!
    private var countryChangedSubject: PassthroughSubject<ILCountry, Never>!
    private var submitTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var backToLoginTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILForgotPasswordUseCase()
        sut = ILForgotPasswordViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        methodChangedSubject = PassthroughSubject<ILForgotPasswordMethod, Never>()
        phoneChangedSubject = PassthroughSubject<String, Never>()
        countryChangedSubject = PassthroughSubject<ILCountry, Never>()
        submitTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        backToLoginTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        methodChangedSubject = nil
        phoneChangedSubject = nil
        countryChangedSubject = nil
        submitTappedSubject = nil
        backTappedSubject = nil
        backToLoginTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeOutput() -> ILForgotPasswordViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            methodChanged: methodChangedSubject.eraseToAnyPublisher(),
            phoneChanged: phoneChangedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            backToLoginTapped: backToLoginTappedSubject.eraseToAnyPublisher()
        ))
    }

    func test_initialState_matchesUseCaseDefault() {
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.method, .phone)
        XCTAssertTrue(mockUseCase.getInitialStateCalled)
    }

    func test_methodChanged_updatesMethodAndClearsSubmitError() {
        mockUseCase.stubbedEntity = ILForgotPasswordEntity(fullPhone: "+84912345678", fullEmail: "user@example.com")
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        methodChangedSubject.send(.email)

        XCTAssertEqual(receivedState?.method, .email)
        XCTAssertEqual(receivedState?.selectedContact, "user@example.com")
        XCTAssertNil(receivedState?.submitError)
    }

    func test_methodChanged_toSameMethod_doesNothing() {
        let output = makeOutput()
        var stateEmissionCount = 0
        output.state
            .sink { _ in stateEmissionCount += 1 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let countAfterLoad = stateEmissionCount
        methodChangedSubject.send(.phone)

        XCTAssertEqual(stateEmissionCount, countAfterLoad)
    }

    func test_phoneChanged_updatesFullPhoneAndEnablesSubmit() {
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        phoneChangedSubject.send("912345678")

        XCTAssertEqual(receivedState?.fullPhone, "+84912345678")
        XCTAssertTrue(receivedState?.isPhoneValid ?? false)
        XCTAssertTrue(receivedState?.isSubmitEnabled ?? false)
    }

    func test_countryChanged_updatesCountryAndReplacesDialCodeKeepingTypedNumber() {
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)
        guard let other = ILCountry.all.first(where: { $0 != .default }) else {
            return XCTFail("Need a second country")
        }

        viewDidLoadSubject.send(())
        phoneChangedSubject.send("912345678")
        countryChangedSubject.send(other)

        XCTAssertEqual(receivedState?.selectedCountry, other)
        XCTAssertEqual(receivedState?.fullPhone, "\(other.dialCode)912345678")
    }

    func test_backTapped_firesGoBackEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILForgotPasswordNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_backToLoginTapped_firesGoBackEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILForgotPasswordNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backToLoginTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_submitTapped_withoutContact_doesNotCallUseCase() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        submitTappedSubject.send(())

        XCTAssertFalse(mockUseCase.sendResetInstructionsCalled)
    }

    func test_submitTapped_withPhoneContact_callsUseCaseAndFiresGoToOtp() {
        mockUseCase.stubbedEntity = ILForgotPasswordEntity(fullPhone: "+84912345678", fullEmail: "user@example.com")
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        let expectation = expectation(description: "goToOtp")
        var receivedEvent: ILForgotPasswordNavEvent?
        sut.navigationEventPublisher
            .sink {
                receivedEvent = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockUseCase.sendResetInstructionsCalled)
        XCTAssertEqual(mockUseCase.sentContact, "+84912345678")
        XCTAssertEqual(receivedEvent, .goToOtp(phoneNumber: "+84912345678"))
        XCTAssertFalse(receivedState!.isSubmitting)
    }

    func test_submitTapped_withEmailContact_firesDidRequestEmailReset() {
        mockUseCase.stubbedEntity = ILForgotPasswordEntity(fullPhone: "+84912345678", fullEmail: "user@example.com")
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestEmailReset")
        var receivedEvent: ILForgotPasswordNavEvent?
        sut.navigationEventPublisher
            .sink {
                receivedEvent = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        methodChangedSubject.send(.email)
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedEvent, .didRequestEmailReset(email: "user@example.com"))
    }

    func test_submitTapped_whenUseCaseFails_setsSubmitErrorAndDoesNotNavigate() {
        mockUseCase.stubbedEntity = ILForgotPasswordEntity(fullPhone: "+84912345678", fullEmail: "user@example.com")
        mockUseCase.sendResetInstructionsError = ILForgotPasswordError.contactNotFound
        let output = makeOutput()
        var receivedState: ILForgotPasswordStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        var receivedEvent: ILForgotPasswordNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        submitTappedSubject.send(())

        let waitExpectation = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { waitExpectation.fulfill() }
        wait(for: [waitExpectation], timeout: 1)

        XCTAssertNotNil(receivedState?.submitError)
        XCTAssertFalse(receivedState!.isSubmitting)
        XCTAssertNil(receivedEvent)
    }
}

// MARK: - Mock ILForgotPasswordUseCase
final class MockILForgotPasswordUseCase: ILForgotPasswordUseCase {
    var getInitialStateCalled = false
    var stubbedEntity = ILForgotPasswordEntity.empty

    var sendResetInstructionsCalled = false
    var sendResetInstructionsError: Error?
    var sentMethod: ILForgotPasswordMethod?
    var sentContact: String?

    func getInitialState() -> ILForgotPasswordEntity {
        getInitialStateCalled = true
        return stubbedEntity
    }

    func sendResetInstructions(method: ILForgotPasswordMethod, contact: String) async throws {
        sendResetInstructionsCalled = true
        sentMethod = method
        sentContact = contact
        if let error = sendResetInstructionsError {
            throw error
        }
    }
}
