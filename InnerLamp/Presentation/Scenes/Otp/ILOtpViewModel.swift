//
//  ILOtpViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILOtpNavEvent: Equatable {
    /// Bấm back trên header hoặc "Đổi email" — quay lại màn trước đó (SignUp), giữ nguyên mọi giá trị.
    case goBack
    /// Xác thực mã thành công.
    case didVerify(email: String)
}

protocol ILOtpViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILOtpCoordinator` subscribes to this
    /// directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILOtpNavEvent, Never> { get }
}

final class ILOtpViewModel: ILOtpViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Gọi từ `ILCodeInputView.onCodeChanged` — không tự validate theo từng ký tự, chỉ xóa
        /// lỗi cũ (nếu có) để người dùng nhập lại.
        let codeChanged: AnyPublisher<String, Never>
        let backTapped: AnyPublisher<Void, Never>
        let changeEmailTapped: AnyPublisher<Void, Never>
        let resendTapped: AnyPublisher<Void, Never>
        let verifyTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILOtpStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILOtpNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILOtpNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILOtpStateModel>, Never>
    private var currentState: ILOtpStateModel
    private let useCase: ILOtpUseCase
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    /// Timing initial (từ `request-otp`) — dùng lại khi `viewDidLoad` dựng state ban đầu.
    private let initialOtpExpiresInSeconds: Int
    private let initialResendAfterSeconds: Int

    // MARK: - Initializer
    init(
        useCase: ILOtpUseCase,
        email: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    ) {
        self.useCase = useCase
        self.initialOtpExpiresInSeconds = otpExpiresInSeconds
        self.initialResendAfterSeconds = resendAfterSeconds
        let initialState = useCase.getInitialState(
            email: email,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.codeChanged
            .sink { [weak self] code in self?.handleCodeChanged(code) }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.handleBackTapped() }
            .store(in: &cancellables)

        input.changeEmailTapped
            .sink { [weak self] _ in self?.handleChangeEmailTapped() }
            .store(in: &cancellables)

        input.resendTapped
            .sink { [weak self] _ in self?.handleResendTapped() }
            .store(in: &cancellables)

        input.verifyTapped
            .sink { [weak self] _ in self?.handleVerifyTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Coi như mã vừa được gửi khi màn này xuất hiện — dựng state từ timing `request-otp` trả về
    /// và bắt đầu đếm ngược.
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState(
            email: currentState.email,
            otpExpiresInSeconds: initialOtpExpiresInSeconds,
            resendAfterSeconds: initialResendAfterSeconds
        )
        stateSubject.send(.success(currentState))
        startCountdown()
    }

    private func handleCodeChanged(_ code: String) {
        currentState.code = code
        currentState.codeError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleBackTapped() {
        navigationEventSubject.send(.goBack)
    }

    private func handleChangeEmailTapped() {
        navigationEventSubject.send(.goBack)
    }

    private func handleResendTapped() {
        guard currentState.canResend else { return }
        requestNewCode()
    }

    private func requestNewCode() {
        guard !currentState.isResending else { return }

        currentState.isResending = true
        currentState.resendError = nil
        stateSubject.send(.success(currentState))

        let email = currentState.email

        Task { [weak self] in
            guard let self else { return }
            do {
                let timing = try await self.useCase.resendCode(email: email)
                self.currentState.isResending = false
                self.currentState.code = ""
                self.currentState.codeError = nil
                self.currentState.resendError = nil
                // Đếm lại từ timing thật server vừa trả về, không dùng hằng số.
                self.currentState.otpExpiresInSeconds = timing.expiresInSeconds
                self.currentState.secondsRemaining = timing.resendAfterSeconds
                self.stateSubject.send(.success(self.currentState))
                self.startCountdown()
            } catch {
                self.currentState.isResending = false
                self.currentState.resendError = error.localizedDescription
                // EN: `OTP_RESEND_TOO_SOON` restarts the resend timer from the server's wait.
                // VI: `OTP_RESEND_TOO_SOON` đếm lại nút gửi lại theo thời gian chờ server trả về.
                if case ILOtpError.resendTooSoon(let retryAfterSeconds?) = error {
                    self.currentState.secondsRemaining = retryAfterSeconds
                    self.stateSubject.send(.success(self.currentState))
                    self.startCountdown()
                    return
                }
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    /// Validate đủ 6 số ở tầng UseCase trước khi gọi API; nút CTA vốn đã disabled cho tới
    /// khi đủ số (`isSubmitEnabled`), guard ở đây phòng gọi trực tiếp.
    private func handleVerifyTapped() {
        guard currentState.isSubmitEnabled else { return }

        currentState.isVerifying = true
        currentState.codeError = nil
        currentState.resendError = nil
        stateSubject.send(.success(currentState))

        let email = currentState.email
        let code = currentState.code

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.verifyCode(email: email, code: code)
                self.currentState.isVerifying = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.didVerify(email: email))
            } catch {
                self.currentState.isVerifying = false
                self.currentState.codeError = error.localizedDescription
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    // MARK: - Countdown
    private func startCountdown() {
        countdownTimer?.invalidate()
        guard currentState.secondsRemaining > 0 else { return }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            guard self.currentState.secondsRemaining > 0 else {
                timer.invalidate()
                return
            }

            self.currentState.secondsRemaining -= 1
            self.stateSubject.send(.success(self.currentState))

            if self.currentState.secondsRemaining == 0 {
                timer.invalidate()
            }
        }
    }
}
