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
    private var changeNumberTappedSubject: PassthroughSubject<Void, Never>!
    private var resendTappedSubject: PassthroughSubject<Void, Never>!
    private var requestVoiceCallTappedSubject: PassthroughSubject<Void, Never>!
    private var verifyTappedSubject: PassthroughSubject<Void, Never>!

    private let phoneNumber = "0901234567"
    /// Timing the OTP screen is entered with — as returned by `request-otp`.
    private let initialOtpExpiresInSeconds = 90
    private let initialResendAfterSeconds = 60

    override func setUp() {
        super.setUp()
        mockUseCase = MockILOtpUseCase()
        sut = ILOtpViewModel(
            useCase: mockUseCase,
            phoneNumber: phoneNumber,
            otpExpiresInSeconds: initialOtpExpiresInSeconds,
            resendAfterSeconds: initialResendAfterSeconds
        )
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        codeChangedSubject = PassthroughSubject<String, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        changeNumberTappedSubject = PassthroughSubject<Void, Never>()
        resendTappedSubject = PassthroughSubject<Void, Never>()
        requestVoiceCallTappedSubject = PassthroughSubject<Void, Never>()
        verifyTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        codeChangedSubject = nil
        backTappedSubject = nil
        changeNumberTappedSubject = nil
        resendTappedSubject = nil
        requestVoiceCallTappedSubject = nil
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
            changeNumberTapped: changeNumberTappedSubject.eraseToAnyPublisher(),
            resendTapped: resendTappedSubject.eraseToAnyPublisher(),
            requestVoiceCallTapped: requestVoiceCallTappedSubject.eraseToAnyPublisher(),
            verifyTapped: verifyTappedSubject.eraseToAnyPublisher()
        ))
    }

    func test_initialState_setsPhoneNumberAndSeedsCountdownFromServerTiming() {
        let output = makeOutput()
        var receivedState: ILOtpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(mockUseCase.getInitialStatePhoneNumber, phoneNumber)
        XCTAssertEqual(mockUseCase.getInitialStateOTPExpiresInSeconds, initialOtpExpiresInSeconds)
        XCTAssertEqual(mockUseCase.getInitialStateResendAfterSeconds, initialResendAfterSeconds)
        XCTAssertEqual(receivedState?.phoneNumber, phoneNumber)
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

    func test_changeNumberTapped_firesGoBackNavEvent() {
        var receivedEvent: ILOtpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)
        _ = makeOutput()

        changeNumberTappedSubject.send(())

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

    func test_requestVoiceCallTapped_callsUseCaseWithVoiceChannelAndRestartsCountdownFromServer() {
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
        requestVoiceCallTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertTrue(mockUseCase.resendCodeCalled)
        XCTAssertEqual(mockUseCase.resendCodeChannel, .voiceCall)
        XCTAssertEqual(receivedState?.code, "")
        XCTAssertEqual(receivedState?.otpExpiresInSeconds, 45)
    }

    func test_resendFailed_setsResendErrorAndKeepsCode() {
        mockUseCase.resendCodeShouldThrow = true
        mockUseCase.resendCodeThrownError = ILOtpError.voiceCallUnsupported

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
        requestVoiceCallTappedSubject.send(())

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(receivedState?.resendError, ILOtpError.voiceCallUnsupported.localizedDescription)
        XCTAssertEqual(receivedState?.code, "123456")
        XCTAssertFalse(receivedState?.isResending ?? true)
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
        XCTAssertEqual(receivedEvent, .didVerify(phoneNumber: phoneNumber))
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
    var getInitialStatePhoneNumber: String?
    var getInitialStateOTPExpiresInSeconds: Int?
    var getInitialStateResendAfterSeconds: Int?

    var resendCodeCalled = false
    var resendCodeChannel: ILOtpChannel?
    var resendCodeShouldThrow = false
    var resendCodeThrownError: Error = ILOtpError.invalidCode
    var resendCodeTimingToReturn = ILOtpTimingEntity(expiresInSeconds: 90, resendAfterSeconds: 60)

    var verifyCodeCalled = false
    var verifyCodeShouldThrow = false
    var verifyCodeThrownError: Error = ILOtpError.invalidCode

    func getInitialState(phoneNumber: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpStateModel {
        getInitialStateCalled = true
        getInitialStatePhoneNumber = phoneNumber
        getInitialStateOTPExpiresInSeconds = otpExpiresInSeconds
        getInitialStateResendAfterSeconds = resendAfterSeconds
        var state = ILOtpStateModel.initial
        state.phoneNumber = phoneNumber
        state.otpExpiresInSeconds = otpExpiresInSeconds
        state.secondsRemaining = resendAfterSeconds
        return state
    }

    func resendCode(phoneNumber: String, channel: ILOtpChannel) async throws -> ILOtpTimingEntity {
        resendCodeCalled = true
        resendCodeChannel = channel
        if resendCodeShouldThrow {
            throw resendCodeThrownError
        }
        return resendCodeTimingToReturn
    }

    func verifyCode(phoneNumber: String, code: String) async throws {
        verifyCodeCalled = true
        if verifyCodeShouldThrow {
            throw verifyCodeThrownError
        }
    }
}
