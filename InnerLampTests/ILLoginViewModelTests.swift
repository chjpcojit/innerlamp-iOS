//
//  ILLoginViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLoginViewModelTests: XCTestCase {

    private var mockUseCase: MockILLoginUseCase!
    private var sut: ILLoginViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var phoneChangedSubject: PassthroughSubject<String, Never>!
    private var countryChangedSubject: PassthroughSubject<ILCountry, Never>!
    private var passwordChangedSubject: PassthroughSubject<String, Never>!
    private var submitTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var signupTappedSubject: PassthroughSubject<Void, Never>!
    private var forgotPasswordTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLoginUseCase()
        sut = ILLoginViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        phoneChangedSubject = PassthroughSubject<String, Never>()
        countryChangedSubject = PassthroughSubject<ILCountry, Never>()
        passwordChangedSubject = PassthroughSubject<String, Never>()
        submitTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        signupTappedSubject = PassthroughSubject<Void, Never>()
        forgotPasswordTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        phoneChangedSubject = nil
        countryChangedSubject = nil
        passwordChangedSubject = nil
        submitTappedSubject = nil
        backTappedSubject = nil
        signupTappedSubject = nil
        forgotPasswordTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeOutput() -> ILLoginViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            phoneChanged: phoneChangedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            passwordChanged: passwordChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            signupTapped: signupTappedSubject.eraseToAnyPublisher(),
            forgotPasswordTapped: forgotPasswordTappedSubject.eraseToAnyPublisher()
        ))
    }

    func test_initialState_matchesUseCaseDefault() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.selectedCountry, .default)
        XCTAssertTrue(receivedState!.isSubmitEnabled)
    }

    func test_countryChanged_updatesSelectedCountry() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let japan = ILCountry.all.first { $0.iso == "JP" }!
        countryChangedSubject.send(japan)

        XCTAssertEqual(receivedState?.selectedCountry, japan)
    }

    func test_backTapped_firesGoToOnboardingEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToOnboarding)
    }

    func test_signupTapped_firesGoToSignupEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        signupTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToSignup)
    }

    func test_forgotPasswordTapped_firesGoToForgotPasswordEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        forgotPasswordTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToForgotPassword)
    }

    func test_submitTapped_withInvalidForm_setsValidationErrorsAndDoesNotCallUseCase() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        phoneChangedSubject.send("091")
        passwordChangedSubject.send("")

        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.phoneError)
        XCTAssertNotNil(receivedState?.passwordError)
        XCTAssertFalse(mockUseCase.loginCalled)
    }

    func test_submitTapped_withValidForm_callsLoginAndFiresDidLoginSuccessfully() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        let expectation = expectation(description: "didLoginSuccessfully")
        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink {
                receivedEvent = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        phoneChangedSubject.send("0912345678")
        passwordChangedSubject.send("secret1")

        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockUseCase.loginCalled)
        XCTAssertEqual(mockUseCase.loggedInPhone, "+84 912 345 678")
        XCTAssertEqual(receivedEvent, .didLoginSuccessfully)
        XCTAssertFalse(receivedState!.isSubmitting)
    }

    func test_submitTapped_whenLoginFails_setsSubmitErrorAndDoesNotNavigate() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        mockUseCase.loginError = ILLoginError.invalidCredentials

        viewDidLoadSubject.send(())
        phoneChangedSubject.send("0912345678")
        passwordChangedSubject.send("wrongpass")

        submitTappedSubject.send(())

        let deadline = DispatchTime.now() + 0.5
        let waitExpectation = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: deadline) { waitExpectation.fulfill() }
        wait(for: [waitExpectation], timeout: 1)

        XCTAssertNotNil(receivedState?.submitError)
        XCTAssertFalse(receivedState!.isSubmitting)
        XCTAssertNil(receivedEvent)
    }
}

// MARK: - Mock ILLoginUseCase
final class MockILLoginUseCase: ILLoginUseCase {
    var loginCalled = false
    var loginError: Error?
    var loggedInPhone: String?

    func getInitialState() -> ILLoginStateModel {
        ILLoginStateModel.initial
    }

    func validatePhone(nationalDigits: String, country: ILCountry) -> String? {
        guard !nationalDigits.isEmpty else { return "required" }
        return country.isValidNationalDigitCount(nationalDigits.count) ? nil : "invalid"
    }

    func validatePassword(_ value: String) -> String? {
        value.isEmpty ? "required" : nil
    }

    func login(_ credential: ILLoginEntity) async throws {
        loginCalled = true
        loggedInPhone = credential.phone
        if let error = loginError {
            throw error
        }
    }
}
