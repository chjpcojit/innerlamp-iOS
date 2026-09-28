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
        let phoneChanged: AnyPublisher<String, Never>
        let countryChanged: AnyPublisher<ILCountry, Never>
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

    /// Snapshot đồng bộ — `ILLoginViewController` dùng để khởi tạo `ILCountryPickerViewController`
    /// (đánh dấu quốc gia đang chọn) ngay tại thời điểm bấm, không dùng để nhận cập nhật liên tục
    /// (cho việc đó dùng `Output.state`).
    var state: ILLoginStateModel { currentState }

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

        input.phoneChanged
            .sink { [weak self] text in self?.handlePhoneChanged(text) }
            .store(in: &cancellables)

        input.countryChanged
            .sink { [weak self] country in self?.handleCountryChanged(country) }
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
    private func handlePhoneChanged(_ text: String) {
        currentState.phone = text
        currentState.phoneError = nil
    }

    private func handleCountryChanged(_ country: ILCountry) {
        guard currentState.selectedCountry != country else { return }
        currentState.selectedCountry = country
        stateSubject.send(.success(currentState))
    }

    private func handlePasswordChanged(_ text: String) {
        currentState.password = text
        currentState.passwordError = nil
    }

    /// Validate toàn bộ form; nếu có lỗi thì render lỗi và dừng, không gọi `login`.
    private func handleSubmit() {
        guard !currentState.isSubmitting else { return }

        currentState.phoneError = useCase.validatePhone(
            nationalDigits: currentState.nationalDigits,
            country: currentState.selectedCountry
        )
        currentState.passwordError = useCase.validatePassword(currentState.password)
        currentState.submitError = nil

        guard !currentState.hasValidationError else {
            stateSubject.send(.success(currentState))
            return
        }

        currentState.isSubmitting = true
        stateSubject.send(.success(currentState))

        let phone = currentState.phoneE164
        let password = currentState.password

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.login(ILLoginEntity(phone: phone, password: password))
                self.currentState.isSubmitting = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.didLoginSuccessfully)
            } catch {
                self.currentState.isSubmitting = false
                self.currentState.submitError = error.localizedDescription
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }
}
