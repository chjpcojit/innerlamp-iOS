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
    private var emailChangedSubject: PassthroughSubject<String, Never>!
    private var passwordChangedSubject: PassthroughSubject<String, Never>!
    private var submitTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var signupTappedSubject: PassthroughSubject<Void, Never>!
    private var forgotPasswordTappedSubject: PassthroughSubject<Void, Never>!
    private var guestPreviewTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLoginUseCase()
        sut = ILLoginViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        emailChangedSubject = PassthroughSubject<String, Never>()
        passwordChangedSubject = PassthroughSubject<String, Never>()
        submitTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        signupTappedSubject = PassthroughSubject<Void, Never>()
        forgotPasswordTappedSubject = PassthroughSubject<Void, Never>()
        guestPreviewTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        emailChangedSubject = nil
        passwordChangedSubject = nil
        submitTappedSubject = nil
        backTappedSubject = nil
        signupTappedSubject = nil
        forgotPasswordTappedSubject = nil
        guestPreviewTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeOutput() -> ILLoginViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            emailChanged: emailChangedSubject.eraseToAnyPublisher(),
            passwordChanged: passwordChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            signupTapped: signupTappedSubject.eraseToAnyPublisher(),
            forgotPasswordTapped: forgotPasswordTappedSubject.eraseToAnyPublisher(),
            guestPreviewTapped: guestPreviewTappedSubject.eraseToAnyPublisher()
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
        XCTAssertEqual(receivedState?.email, "")
        XCTAssertTrue(receivedState!.isSubmitEnabled)
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

    func test_guestPreviewTapped_firesGoToGuestPreviewEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILLoginNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        guestPreviewTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToGuestPreview)
    }

    func test_submitTapped_withInvalidForm_setsValidationErrorsAndDoesNotCallUseCase() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        emailChangedSubject.send("   ")
        passwordChangedSubject.send("")

        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.emailError)
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
        emailChangedSubject.send("  an@example.com ")
        passwordChangedSubject.send("secret1")

        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockUseCase.loginCalled)
        XCTAssertEqual(mockUseCase.loggedInEmail, "an@example.com")
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
        emailChangedSubject.send("an@example.com")
        passwordChangedSubject.send("wrongpass")

        submitTappedSubject.send(())

        let deadline = DispatchTime.now() + 0.5
        let waitExpectation = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: deadline) { waitExpectation.fulfill() }
        wait(for: [waitExpectation], timeout: 1)

        XCTAssertNotNil(receivedState?.submitError)
        XCTAssertFalse(receivedState!.isSubmitting)
        XCTAssertNil(receivedEvent)
        // EN: Criterion 3 — keep the email, clear the password.
        // VI: Tiêu chí 3 — giữ email, xoá mật khẩu.
        XCTAssertEqual(receivedState?.email, "an@example.com")
        XCTAssertEqual(receivedState?.password, "")
    }

    func test_submitTapped_whenServerSaysInvalidEmail_showsItUnderTheEmailField() {
        let output = makeOutput()
        var receivedState: ILLoginStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        mockUseCase.loginError = ILLoginError.invalidEmail

        viewDidLoadSubject.send(())
        emailChangedSubject.send("not-an-email")
        passwordChangedSubject.send("secret12")

        submitTappedSubject.send(())

        let waitExpectation = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { waitExpectation.fulfill() }
        wait(for: [waitExpectation], timeout: 1)

        XCTAssertEqual(receivedState?.emailError, ILLoginError.invalidEmail.localizedDescription)
        XCTAssertNil(receivedState?.submitError)
    }
}

// MARK: - Mock ILLoginUseCase
final class MockILLoginUseCase: ILLoginUseCase {
    var loginCalled = false
    var loginError: Error?
    var loggedInEmail: String?

    func getInitialState() -> ILLoginStateModel {
        ILLoginStateModel.initial
    }

    func validateEmail(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "required" : nil
    }

    func validatePassword(_ value: String) -> String? {
        value.isEmpty ? "required" : nil
    }

    func login(_ credential: ILLoginEntity) async throws {
        loginCalled = true
        loggedInEmail = credential.email
        if let error = loginError {
            throw error
        }
    }
}
