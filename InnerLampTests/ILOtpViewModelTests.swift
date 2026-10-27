//
//  ILOtpViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILOtpViewModelTests: XCTestCase {

    private var mockUseCase: MockILOtpUseCase!
    private var sut: ILOtpViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var codeChangedSubject: PassthroughSubject<String, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var changeEmailTappedSubject: PassthroughSubject<Void, Never>!
    private var resendTappedSubject: PassthroughSubject<Void, Never>!
    private var verifyTappedSubject: PassthroughSubject<Void, Never>!

    private let email = "an@example.com"
    /// Timing the OTP screen is entered with — as returned by `request-otp`.
    private let initialOtpExpiresInSeconds = 90
    private let initialResendAfterSeconds = 60

    override func setUp() {
        super.setUp()
        mockUseCase = MockILOtpUseCase()
        sut = ILOtpViewModel(
            useCase: mockUseCase,
            email: email,
            otpExpiresInSeconds: initialOtpExpiresInSeconds,
            resendAfterSeconds: initialResendAfterSeconds
        )
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        codeChangedSubject = PassthroughSubject<String, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        changeEmailTappedSubject = PassthroughSubject<Void, Never>()
        resendTappedSubject = PassthroughSubject<Void, Never>()
        verifyTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        codeChangedSubject = nil
        backTappedSubject = nil
        changeEmailTappedSubject = nil
        resendTappedSubject = nil
        verifyTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeOutput() -> ILOtpViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            codeChanged: codeChangedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            changeEmailTapped: changeEmailTappedSubject.eraseToAnyPublisher(),
            resendTapped: resendTappedSubject.eraseToAnyPublisher(),
            verifyTapped: verifyTappedSubject.eraseToAnyPublisher()
        ))
    }

    /// EN: Rebuilds the SUT with no resend wait so "Gửi lại" is enabled at once.
    /// VI: Dựng lại SUT không có thời gian chờ để nút "Gửi lại" bật ngay.
    private func makeSutWithResendAvailable() {
        sut = ILOtpViewModel(
            useCase: mockUseCase,
            email: email,
            otpExpiresInSeconds: initialOtpExpiresInSeconds,
            resendAfterSeconds: 0
        )
    }

    func test_initialState_setsEmailAndSeedsCountdownFromServerTiming() {
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(mockUseCase.getInitialStateEmail, email)
        XCTAssertEqual(mockUseCase.getInitialStateOTPExpiresInSeconds, initialOtpExpiresInSeconds)
        XCTAssertEqual(mockUseCase.getInitialStateResendAfterSeconds, initialResendAfterSeconds)
        XCTAssertEqual(receivedState?.email, email)
        XCTAssertEqual(receivedState?.secondsRemaining, initialResendAfterSeconds)
        XCTAssertEqual(receivedState?.otpExpiresInSeconds, initialOtpExpiresInSeconds)
        XCTAssertFalse(receivedState?.canResend ?? true)
    }

    func test_initialState_expiryTextIsBuiltFromServerExpiry() {
        var receivedState: ILOtpStateModel?
        makeOutput().state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        // 90s → "1 phút 30 giây" — the server value, not the old hardcoded "10 phút".
        XCTAssertEqual(receivedState?.expiryText.contains("1 phút 30 giây"), true)
    }

    func test_codeChanged_updatesCodeAndClearsError() {
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123456")

        XCTAssertEqual(receivedState?.code, "123456")
        XCTAssertNil(receivedState?.codeError)
        XCTAssertTrue(receivedState?.isCodeComplete == true)
    }

    func test_backTapped_firesGoBackNavEvent() {
        var receivedEvent: ILOtpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)
        _ = makeOutput()

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_changeEmailTapped_firesGoBackNavEvent() {
        var receivedEvent: ILOtpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)
        _ = makeOutput()

        changeEmailTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    /// Nút "Gửi lại" vẫn còn cooldown ngay sau `viewDidLoad` (`canResend == false`) — guard
    /// trong `handleResendTapped` phải chặn gọi `useCase.resendCode` dù có bấm.
    func test_resendTapped_whileCooldownActive_doesNotCallUseCase() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        resendTappedSubject.send(())

        XCTAssertFalse(mockUseCase.resendCodeCalled)
    }

    func test_resendTapped_afterWait_callsUseCaseWithEmailAndRestartsCountdownFromServer() {
        makeSutWithResendAvailable()
        // Resend returns a fresh, different timing — the countdown must adopt it, not a constant.
        mockUseCase.resendCodeTimingToReturn = ILOtpTimingEntity(expiresInSeconds: 45, resendAfterSeconds: 12)

        let expectation = expectation(description: "state reseeded from resend timing")
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { [self] state in
                if case .success(let model) = state, model.secondsRemaining == 12, !model.isResending {
                    receivedState = model
                    if mockUseCase.resendCodeCalled { expectation.fulfill() }
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123456")
        resendTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(mockUseCase.resendCodeCalled)
        XCTAssertEqual(mockUseCase.resendCodeEmail, email)
        XCTAssertEqual(receivedState?.code, "")
        XCTAssertEqual(receivedState?.otpExpiresInSeconds, 45)
    }

    func test_resendFailed_setsResendErrorAndKeepsCode() {
        makeSutWithResendAvailable()
        mockUseCase.resendCodeShouldThrow = true
        mockUseCase.resendCodeThrownError = ILOtpError.sendLimited(lockedUntil: nil)

        let expectation = expectation(description: "resendError set")
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state, model.resendError != nil {
                    receivedState = model
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123456")
        resendTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(receivedState?.resendError, ILOtpError.sendLimited(lockedUntil: nil).localizedDescription)
        XCTAssertEqual(receivedState?.code, "123456")
        XCTAssertFalse(receivedState?.isResending ?? true)
    }

    func test_resendTooSoon_restartsTheResendTimerFromTheServerWait() {
        makeSutWithResendAvailable()
        mockUseCase.resendCodeShouldThrow = true
        mockUseCase.resendCodeThrownError = ILOtpError.resendTooSoon(retryAfterSeconds: 25)

        let expectation = expectation(description: "timer restarted from retry_after_seconds")
        let output = makeOutput()
        output.state
            .sink { state in
                if case .success(let model) = state, model.resendError != nil, model.secondsRemaining == 25 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        resendTappedSubject.send(())

        wait(for: [expectation], timeout: 2)
    }

    func test_verifyTapped_whenCodeValid_callsUseCaseAndFiresDidVerify() {
        let expectation = expectation(description: "didVerify nav event fired")
        var receivedEvent: ILOtpNavEvent?
        sut.navigationEventPublisher
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123456")
        verifyTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(mockUseCase.verifyCodeCalled)
        XCTAssertEqual(receivedEvent, .didVerify(email: email))
    }

    func test_verifyTapped_whenCodeInvalid_showsCodeError() {
        mockUseCase.verifyCodeShouldThrow = true
        let expectation = expectation(description: "codeError set after failed verify")
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state, model.codeError != nil {
                    receivedState = model
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123456")
        verifyTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(receivedState?.codeError, ILOtpError.invalidCode.localizedDescription)
        XCTAssertFalse(receivedState?.isVerifying ?? true)
    }

    /// Nút CTA vốn đã disabled khi mã chưa đủ 6 số (`isSubmitEnabled == false`) — guard trong
    /// `handleVerifyTapped` phải chặn gọi `useCase.verifyCode` dù `verifyTapped` được bắn.
    func test_verifyTapped_whenCodeIncomplete_doesNotCallUseCase() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        codeChangedSubject.send("123")
        verifyTappedSubject.send(())

        XCTAssertFalse(mockUseCase.verifyCodeCalled)
    }
}

// MARK: - Mock ILOtpUseCase

/// Test double for `ILOtpUseCase` — the ViewModel tests are about presentation state/navigation,
/// so the whole UseCase is stubbed. The real UseCase's session-persistence and error-mapping
/// behaviour is covered by `ILOtpUseCaseTests` / `ILOtpRepositoryTests`.
final class MockILOtpUseCase: ILOtpUseCase {
    var getInitialStateCalled = false
    var getInitialStateEmail: String?
    var getInitialStateOTPExpiresInSeconds: Int?
    var getInitialStateResendAfterSeconds: Int?

    var resendCodeCalled = false
    var resendCodeEmail: String?
    var resendCodeShouldThrow = false
    var resendCodeThrownError: Error = ILOtpError.invalidCode
    var resendCodeTimingToReturn = ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60)

    var verifyCodeCalled = false
    var verifyCodeShouldThrow = false
    var verifyCodeThrownError: Error = ILOtpError.invalidCode

    func getInitialState(email: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel {
        getInitialStateCalled = true
        getInitialStateEmail = email
        getInitialStateOTPExpiresInSeconds = otpExpiresInSeconds
        getInitialStateResendAfterSeconds = resendAfterSeconds
        var state = ILOtpStateModel.initial
        state.email = email
        state.otpExpiresInSeconds = otpExpiresInSeconds
        state.secondsRemaining = resendAfterSeconds
        return state
    }

    func resendCode(email: String) async throws -> ILOtpTimingEntity {
        resendCodeCalled = true
        resendCodeEmail = email
        if resendCodeShouldThrow {
            throw resendCodeThrownError
        }
        return resendCodeTimingToReturn
    }

    func verifyCode(email: String, code: String) async throws {
        verifyCodeCalled = true
        if verifyCodeShouldThrow {
            throw verifyCodeThrownError
        }
    }
}
