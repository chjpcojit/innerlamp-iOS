//
//  ILForgotPasswordViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILForgotPasswordNavEvent: Equatable {
    /// Bấm back trên header hoặc "Trở lại đăng nhập" — quay lại màn Đăng nhập.
    case goBack
    /// Đã gửi hướng dẫn tới số điện thoại — mượn lại luồng OTP xác thực đã có.
    case goToOtp(phoneNumber: String)
    /// Đã gửi hướng dẫn qua email — xác thực đặt lại mật khẩu qua email chưa có trong scope hiện tại.
    case didRequestEmailReset(email: String)
}

protocol ILForgotPasswordViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILForgotPasswordCoordinator` subscribes
    /// to this directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILForgotPasswordNavEvent, Never> { get }
}

final class ILForgotPasswordViewModel: ILForgotPasswordViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let methodChanged: AnyPublisher<ILForgotPasswordMethod, Never>
        let phoneChanged: AnyPublisher<String, Never>
        let countryChanged: AnyPublisher<ILCountry, Never>
        let submitTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let backToLoginTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILForgotPasswordStateModel>, Never>
    }

    // MARK: - Properties
    /// Snapshot đồng bộ — `ILForgotPasswordViewController` dùng để khởi tạo
    /// `ILCountryPickerViewController` (đánh dấu quốc gia đang chọn) ngay tại thời điểm bấm.
    var state: ILForgotPasswordStateModel { currentState }

    var navigationEventPublisher: AnyPublisher<ILForgotPasswordNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILForgotPasswordNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILForgotPasswordStateModel>, Never>
    private var currentState: ILForgotPasswordStateModel
    private let useCase: ILForgotPasswordUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILForgotPasswordUseCase) {
        self.useCase = useCase
        var initialState = ILForgotPasswordStateModel.initial
        Self.applyEntity(useCase.getInitialState(), to: &initialState)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.methodChanged
            .sink { [weak self] method in self?.handleMethodChanged(method) }
            .store(in: &cancellables)

        input.phoneChanged
            .sink { [weak self] text in self?.handlePhoneChanged(text) }
            .store(in: &cancellables)

        input.countryChanged
            .sink { [weak self] country in self?.handleCountryChanged(country) }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] _ in self?.handleSubmit() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.backToLoginTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        Self.applyEntity(useCase.getInitialState(), to: &currentState)
        stateSubject.send(.success(currentState))
    }

    private func handleMethodChanged(_ method: ILForgotPasswordMethod) {
        guard currentState.method != method else { return }
        currentState.method = method
        currentState.submitError = nil
        stateSubject.send(.success(currentState))
    }

    /// Người dùng gõ trực tiếp vào `ILPhoneField` — chưa đăng nhập nên app không có sẵn số này
    /// (khác `ILForgotPasswordEntity.fullPhone`, vốn chỉ có giá trị khi Keychain/Auth API thật
    /// điền sẵn trong tương lai).
    private func handlePhoneChanged(_ text: String) {
        currentState.nationalPhone = text
        currentState.fullPhone = "\(currentState.selectedCountry.dialCode)\(text)"
        currentState.submitError = nil
        stateSubject.send(.success(currentState))
    }

    /// Đổi mã vùng — dựng lại `fullPhone` từ số quốc gia đã gõ để mã vùng mới thay mã cũ.
    private func handleCountryChanged(_ country: ILCountry) {
        guard currentState.selectedCountry != country else { return }
        currentState.selectedCountry = country
        currentState.fullPhone = "\(country.dialCode)\(currentState.nationalPhone)"
        currentState.submitError = nil
        stateSubject.send(.success(currentState))
    }

    /// Nút CTA vốn đã disabled khi thiếu liên hệ (`isSubmitEnabled`), guard ở đây phòng gọi
    /// trực tiếp.
    private func handleSubmit() {
        guard !currentState.isSubmitting, currentState.isSubmitEnabled else { return }

        currentState.isSubmitting = true
        currentState.submitError = nil
        stateSubject.send(.success(currentState))

        let method = currentState.method
        let contact = currentState.selectedContact

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.sendResetInstructions(method: method, contact: contact)
                self.currentState.isSubmitting = false
                self.stateSubject.send(.success(self.currentState))

                switch method {
                case .phone:
                    self.navigationEventSubject.send(.goToOtp(phoneNumber: contact))
                case .email:
                    self.navigationEventSubject.send(.didRequestEmailReset(email: contact))
                }
            } catch {
                self.currentState.isSubmitting = false
                self.currentState.submitError = error.localizedDescription
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    /// `Entity <-> StateModel` conversion is presentation-specific (which fields are mirrored,
    /// defaults) — belongs on the ViewModel, not in a shared Mapper (see
    /// `references/data_layer_boundaries.md`).
    private static func applyEntity(_ entity: ILForgotPasswordEntity, to state: inout ILForgotPasswordStateModel) {
        state.fullPhone = entity.fullPhone
        state.fullEmail = entity.fullEmail
    }
}
