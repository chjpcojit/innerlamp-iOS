//
//  ILSignUpViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSignUpNavEvent: Equatable {
    /// Người dùng bấm nút back trên header — quay lại màn trước đó (Onboarding).
    case goBack
    /// Người dùng bấm "Tôi đã có tài khoản".
    case goToLogin
    /// Gửi mã OTP thành công — sang màn xác thực. Kèm timing của server để màn OTP khởi tạo
    /// countdown "Gửi lại" và câu hiển thị hạn mã bằng giá trị thật.
    case didRequestVerification(phoneNumber: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int)
    /// "Không thấy chùa của bạn?" — mở màn "Thêm thông tin chùa", điền sẵn từ khoá đang tìm và
    /// kèm danh bạ đã tải để chặn trùng.
    case openAddTemple(prefillName: String, existingPlaces: [ILOrdinationPlaceEntity])
}

protocol ILSignUpViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILSignUpCoordinator` subscribes to this
    /// directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILSignUpNavEvent, Never> { get }
}

final class ILSignUpViewModel: ILSignUpViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let suggestDisplayNameTapped: AnyPublisher<Void, Never>
        let displayNameChanged: AnyPublisher<String, Never>
        let ordinationPlaceChanged: AnyPublisher<String, Never>
        /// Người dùng mở bộ chọn nơi xuất gia — tải danh sách chùa nếu chưa có.
        let ordinationPickerOpened: AnyPublisher<Void, Never>
        /// Từ khoá đang gõ trong bộ chọn khi bấm "Thêm thông tin chùa".
        let addTempleTapped: AnyPublisher<String, Never>
        let countryChanged: AnyPublisher<ILCountry, Never>
        let phoneNumberChanged: AnyPublisher<String, Never>
        let emailChanged: AnyPublisher<String, Never>
        let passwordChanged: AnyPublisher<String, Never>
        let togglePasswordVisibilityTapped: AnyPublisher<Void, Never>
        let toggleTermsTapped: AnyPublisher<Void, Never>
        let submitTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let loginPromptTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSignUpStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSignUpNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    /// Snapshot đồng bộ của state hiện tại — dùng bởi `ILSignUpViewController` để khởi tạo
    /// `ILCountryPickerViewController` (đánh dấu quốc gia đang chọn) ngay tại thời điểm bấm, không
    /// dùng để nhận cập nhật liên tục (cho việc đó dùng `Output.state`).
    var state: ILSignUpStateModel { currentState }

    private let navigationEventSubject = PassthroughSubject<ILSignUpNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILSignUpStateModel>, Never>
    private var currentState: ILSignUpStateModel
    private let useCase: ILSignUpUseCase
    private let ordinationPlaceUseCase: ILOrdinationPlaceUseCase
    private var hasLoadedOrdinationPlaces = false
    private static let proposedIDPrefix = "proposed-"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSignUpUseCase, ordinationPlaceUseCase: ILOrdinationPlaceUseCase) {
        self.useCase = useCase
        self.ordinationPlaceUseCase = ordinationPlaceUseCase
        let initialState = useCase.getInitialState()
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.suggestDisplayNameTapped
            .sink { [weak self] _ in self?.handleSuggestDisplayName() }
            .store(in: &cancellables)

        input.displayNameChanged
            .sink { [weak self] text in self?.handleDisplayNameChanged(text) }
            .store(in: &cancellables)

        input.ordinationPlaceChanged
            .sink { [weak self] text in self?.handleOrdinationPlaceChanged(text) }
            .store(in: &cancellables)

        input.ordinationPickerOpened
            .sink { [weak self] _ in self?.handleOrdinationPickerOpened() }
            .store(in: &cancellables)

        input.addTempleTapped
            .sink { [weak self] query in self?.handleAddTempleTapped(query) }
            .store(in: &cancellables)

        input.countryChanged
            .sink { [weak self] country in self?.handleCountryChanged(country) }
            .store(in: &cancellables)

        input.phoneNumberChanged
            .sink { [weak self] text in self?.handlePhoneNumberChanged(text) }
            .store(in: &cancellables)

        input.emailChanged
            .sink { [weak self] text in self?.handleEmailChanged(text) }
            .store(in: &cancellables)

        input.passwordChanged
            .sink { [weak self] text in self?.handlePasswordChanged(text) }
            .store(in: &cancellables)

        input.togglePasswordVisibilityTapped
            .sink { [weak self] _ in self?.handleTogglePasswordVisibility() }
            .store(in: &cancellables)

        input.toggleTermsTapped
            .sink { [weak self] _ in self?.handleToggleTerms() }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] _ in self?.handleSubmit() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.loginPromptTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goToLogin) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState()
        stateSubject.send(.success(currentState))
    }

    /// Chuyển sang pháp danh kế tiếp trong `dharmaNameSuggestions` khi bấm chip "Gợi ý"
    /// (`rollName`) — ghi đè giá trị người dùng đang gõ, khác với `handleDisplayNameChanged` chỉ
    /// đồng bộ khi gõ tay.
    private func handleSuggestDisplayName() {
        let suggestions = useCase.dharmaNameSuggestions
        guard !suggestions.isEmpty else { return }
        currentState.displayNameSuggestionIndex += 1
        currentState.displayName = suggestions[currentState.displayNameSuggestionIndex % suggestions.count]
        currentState.displayNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleDisplayNameChanged(_ text: String) {
        currentState.displayName = text
        currentState.displayNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleOrdinationPlaceChanged(_ text: String) {
        currentState.ordinationPlace = text
        currentState.selectedOrdinationPlaceID = nil
        stateSubject.send(.success(currentState))
    }

    private func handleAddTempleTapped(_ query: String) {
        navigationEventSubject.send(.openAddTemple(
            prefillName: query,
            existingPlaces: currentState.ordinationPlaceOptions
        ))
    }

    /// Nhận chùa vừa đề xuất từ màn "Thêm thông tin chùa": đưa lên đầu danh sách (nhãn "Đang chờ
    /// duyệt") và chọn luôn làm nơi xuất gia. Chưa có API gửi đề xuất (TD-SignUp-002).
    func applyProposedPlace(_ proposal: ILTempleProposalEntity) {
        let place = [proposal.address, proposal.province].filter { !$0.isEmpty }.joined(separator: ", ")
        let pending = "signup.ordination.pending".localized
        let entity = ILOrdinationPlaceEntity(
            id: "\(Self.proposedIDPrefix)\(UUID().uuidString)",
            name: proposal.name,
            subtitle: place.isEmpty ? pending : "\(place) · \(pending)"
        )
        currentState.ordinationPlaceOptions.insert(entity, at: 0)
        currentState.ordinationPlace = proposal.name
        currentState.selectedOrdinationPlaceID = entity.id
        stateSubject.send(.success(currentState))
    }

    /// Danh bạ chùa chỉ cần tải một lần; lỗi thì để trống — người dùng vẫn chọn "Chưa xuất gia"
    /// hoặc thêm chùa, và lần mở sau sẽ thử tải lại.
    private func handleOrdinationPickerOpened() {
        guard !hasLoadedOrdinationPlaces, !currentState.isLoadingOrdinationPlaces else { return }
        currentState.isLoadingOrdinationPlaces = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            let loaded = try? await self.ordinationPlaceUseCase.loadPlaces()
            self.hasLoadedOrdinationPlaces = loaded != nil
            // Giữ các chùa người dùng vừa đề xuất trong lúc chờ tải xong.
            let proposed = self.currentState.ordinationPlaceOptions.filter { $0.id.hasPrefix(Self.proposedIDPrefix) }
            self.currentState.ordinationPlaceOptions = proposed + (loaded ?? [])
            self.currentState.isLoadingOrdinationPlaces = false
            self.stateSubject.send(.success(self.currentState))
        }
    }

    private func handleCountryChanged(_ country: ILCountry) {
        currentState.selectedCountry = country
        currentState.phoneNumberError = nil
        stateSubject.send(.success(currentState))
    }

    private func handlePhoneNumberChanged(_ text: String) {
        currentState.phoneNumber = text
        currentState.phoneNumberError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleEmailChanged(_ text: String) {
        currentState.email = text
        currentState.emailError = nil
        stateSubject.send(.success(currentState))
    }

    /// `ILStrengthMeterView` cần cập nhật độ mạnh mật khẩu theo thời gian thực (đúng thiết kế — 3
    /// vạch + nhãn "Yếu/Khá tốt/Mạnh") — an toàn vì `updateUI` không bao giờ set lại `.text` của
    /// bất kỳ field nào, chỉ đồng bộ phần hiển thị phái sinh.
    private func handlePasswordChanged(_ text: String) {
        currentState.password = text
        currentState.passwordError = nil
        currentState.passwordStrength = useCase.passwordStrength(for: text)
        stateSubject.send(.success(currentState))
    }

    private func handleTogglePasswordVisibility() {
        currentState.isPasswordVisible.toggle()
        stateSubject.send(.success(currentState))
    }

    private func handleToggleTerms() {
        currentState.didAcceptTerms.toggle()
        stateSubject.send(.success(currentState))
    }

    /// Validate toàn bộ form; nếu có lỗi thì render lỗi và dừng, không gọi `sendVerificationCode`.
    /// Nút CTA chỉ hiện "bật" khi đã tick điều khoản (`isSubmitEnabled`), nhưng vẫn guard ở đây
    /// phòng trường hợp gọi trực tiếp.
    private func handleSubmit() {
        guard !currentState.isSubmitting, currentState.didAcceptTerms else { return }

        currentState.displayNameError = useCase.validateDisplayName(currentState.displayName)
        currentState.phoneNumberError = useCase.validatePhoneNumber(
            nationalDigits: currentState.nationalDigits,
            country: currentState.selectedCountry
        )
        currentState.emailError = useCase.validateEmail(currentState.email)
        currentState.passwordError = useCase.validatePassword(currentState.password)
        currentState.submitError = nil

        guard !currentState.hasValidationError else {
            stateSubject.send(.success(currentState))
            return
        }

        currentState.isSubmitting = true
        stateSubject.send(.success(currentState))

        let displayName = currentState.displayName
        let ordinationPlace = currentState.ordinationPlace.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneE164 = currentState.phoneE164
        let email = currentState.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = currentState.password

        Task { [weak self] in
            guard let self else { return }
            do {
                let otp = try await self.useCase.sendVerificationCode(displayName: displayName, ordinationPlace: ordinationPlace, phoneNumber: phoneE164, email: email, password: password)
                self.currentState.isSubmitting = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.didRequestVerification(
                    phoneNumber: phoneE164,
                    otpExpiresInSeconds: otp.expiresInSeconds,
                    resendAfterSeconds: otp.resendAfterSeconds
                ))
            } catch {
                // Kể cả `ILSignUpError.phoneAlreadyRegistered` — chỉ báo lỗi (alert) và ở lại màn
                // hình, không tự chuyển sang Đăng nhập.
                self.currentState.isSubmitting = false
                self.currentState.submitError = error.localizedDescription
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }
}
