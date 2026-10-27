//
//  ILLoginViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLoginNavEvent: Equatable {
    /// Người dùng bấm chip back trên header — quay lại Onboarding (điểm vào của Login).
    case goToOnboarding
    /// Người dùng bấm "Tạo tài khoản mới".
    case goToSignup
    /// Người dùng bấm "Quên?" cạnh mật khẩu — sang luồng Quên mật khẩu.
    case goToForgotPassword
    /// Đăng nhập thành công — sang luồng chính (Home, chưa có trong scope hiện tại).
    case didLoginSuccessfully
    /// Người dùng bấm "Xem trước, đăng nhập sau" — vào luồng chính không cần đăng nhập.
    case goToGuestPreview
}

protocol ILLoginViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILLoginCoordinator` subscribes to this
    /// directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILLoginNavEvent, Never> { get }
}

final class ILLoginViewModel: ILLoginViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let emailChanged: AnyPublisher<String, Never>
        let passwordChanged: AnyPublisher<String, Never>
        let submitTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let signupTapped: AnyPublisher<Void, Never>
        let forgotPasswordTapped: AnyPublisher<Void, Never>
        let guestPreviewTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLoginStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLoginNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLoginNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILLoginStateModel>, Never>
    private var currentState: ILLoginStateModel
    private let useCase: ILLoginUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILLoginUseCase) {
        self.useCase = useCase
        let initialState = useCase.getInitialState()
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.emailChanged
            .sink { [weak self] text in self?.handleEmailChanged(text) }
            .store(in: &cancellables)

        input.passwordChanged
            .sink { [weak self] text in self?.handlePasswordChanged(text) }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] _ in self?.handleSubmit() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in
                self?.navigationEventSubject.send(.goToOnboarding) }
            .store(in: &cancellables)

        input.signupTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goToSignup) }
            .store(in: &cancellables)

        input.forgotPasswordTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goToForgotPassword) }
            .store(in: &cancellables)

        input.guestPreviewTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goToGuestPreview) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState()
        stateSubject.send(.success(currentState))
    }

    /// Không render lại — tránh set lại `ILField.text` trong lúc đang gõ (dễ làm nhảy con trỏ).
    /// Lỗi field liên quan được xóa ngay khi họ sửa lại.
    private func handleEmailChanged(_ text: String) {
        currentState.email = text
        currentState.emailError = nil
    }

    private func handlePasswordChanged(_ text: String) {
        currentState.password = text
        currentState.passwordError = nil
    }

    /// Validate toàn bộ form; nếu có lỗi thì render lỗi và dừng, không gọi `login`.
    private func handleSubmit() {
        guard !currentState.isSubmitting else { return }

        currentState.emailError = useCase.validateEmail(currentState.email)
        currentState.passwordError = useCase.validatePassword(currentState.password)
        currentState.submitError = nil

        guard !currentState.hasValidationError else {
            stateSubject.send(.success(currentState))
            return
        }

        currentState.isSubmitting = true
        stateSubject.send(.success(currentState))

        let email = currentState.trimmedEmail
        let password = currentState.password

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.login(ILLoginEntity(email: email, password: password))
                self.currentState.isSubmitting = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.didLoginSuccessfully)
            } catch {
                // EN: Keep the email, clear the password (criterion 3); `INVALID_EMAIL` goes under the email field.
                // VI: Giữ email, xoá mật khẩu (tiêu chí 3); `INVALID_EMAIL` hiện dưới ô email.
                self.currentState.isSubmitting = false
                self.currentState.password = ""
                if case ILLoginError.invalidEmail = error {
                    self.currentState.emailError = error.localizedDescription
                } else {
                    self.currentState.submitError = error.localizedDescription
                }
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }
}
