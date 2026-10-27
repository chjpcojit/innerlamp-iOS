//
//  ILSignUpViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

/// Dòng người dùng vừa chọn trong bộ chọn nơi xuất gia. `id == nil` là "Chưa xuất gia".
struct ILOrdinationPlaceSelection: Equatable {
    let id: String?
    let name: String
}

enum ILSignUpNavEvent: Equatable {
    /// Người dùng bấm nút back trên header — quay lại màn trước đó (Onboarding).
    case goBack
    /// Người dùng bấm "Tôi đã có tài khoản".
    case goToLogin
    /// Gửi mã OTP thành công — sang màn xác thực. Kèm timing của server để màn OTP khởi tạo
    /// countdown "Gửi lại" và câu hiển thị hạn mã bằng giá trị thật.
    case didRequestVerification(email: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int)
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
        let fullNameChanged: AnyPublisher<String, Never>
        let suggestDisplayNameTapped: AnyPublisher<Void, Never>
        let displayNameChanged: AnyPublisher<String, Never>
        let ordinationPlaceChanged: AnyPublisher<ILOrdinationPlaceSelection, Never>
        /// Người dùng mở bộ chọn nơi xuất gia — tải danh sách chùa nếu chưa có.
        let ordinationPickerOpened: AnyPublisher<Void, Never>
        /// Từ khoá tìm chùa (mỗi lần gõ) — ViewModel debounce rồi tìm bằng `?q=` của server.
        let ordinationSearchChanged: AnyPublisher<String, Never>
        /// Danh sách đã cuộn gần cuối — tải trang kế tiếp.
        let ordinationLoadMoreRequested: AnyPublisher<Void, Never>
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
    /// Từ khoá (đã trim) mà `ordinationPlaceOptions` đang tương ứng; rỗng = không lọc.
    private var ordinationQuery = ""
    private var ordinationNextPage = 1
    /// Tăng mỗi lần bắt đầu một lượt tải mới — phản hồi của lượt cũ (từ khoá đã đổi) bị bỏ.
    private var ordinationRequestToken = 0
    private static let proposedIDPrefix = "proposed-"
    private static let ordinationSearchDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
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

        input.fullNameChanged
            .sink { [weak self] text in self?.handleFullNameChanged(text) }
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

        input.ordinationSearchChanged
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: Self.ordinationSearchDebounce, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in self?.handleOrdinationSearchChanged(query) }
            .store(in: &cancellables)

        input.ordinationLoadMoreRequested
            .sink { [weak self] _ in self?.loadMoreOrdinationPlaces() }
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
    /// EN: The field starts empty, so the first tap shows the first suggestion.
    /// VI: Ô bắt đầu trống nên lần bấm đầu hiện gợi ý đầu tiên.
    private func handleSuggestDisplayName() {
        let suggestions = useCase.dharmaNameSuggestions
        guard !suggestions.isEmpty else { return }
        currentState.displayName = suggestions[currentState.displayNameSuggestionIndex % suggestions.count]
        currentState.displayNameSuggestionIndex += 1
        currentState.displayNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleFullNameChanged(_ text: String) {
        currentState.fullName = text
        currentState.fullNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleDisplayNameChanged(_ text: String) {
        currentState.displayName = text
        currentState.displayNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleOrdinationPlaceChanged(_ selection: ILOrdinationPlaceSelection) {
        currentState.ordinationPlace = selection.name
        currentState.selectedOrdinationPlaceID = selection.id
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
        let place = [proposal.address, proposal.ward, proposal.province].filter { !$0.isEmpty }.joined(separator: ", ")
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

    /// Trang đầu của danh bạ chỉ tải khi mở bộ chọn lần đầu; lỗi thì để trống — người dùng vẫn
    /// chọn "Chưa xuất gia" hoặc thêm chùa, và lần mở sau sẽ thử tải lại.
    private func handleOrdinationPickerOpened() {
        guard !hasLoadedOrdinationPlaces, !currentState.isLoadingOrdinationPlaces else { return }
        reloadOrdinationPlaces(query: ordinationQuery)
    }

    private func handleOrdinationSearchChanged(_ query: String) {
        guard query != ordinationQuery else { return }
        reloadOrdinationPlaces(query: query)
    }

    /// Bỏ kết quả cũ và tải lại từ trang 1 theo `query` (server tìm theo tên chùa).
    private func reloadOrdinationPlaces(query: String) {
        ordinationQuery = query
        ordinationNextPage = 1
        ordinationRequestToken += 1
        let token = ordinationRequestToken

        // Không để lại kết quả của từ khoá cũ trong lúc chờ; chùa vừa đề xuất luôn được giữ.
        currentState.ordinationPlaceOptions = proposedOrdinationPlaces(matching: query)
        currentState.hasMoreOrdinationPlaces = false
        currentState.isLoadingMoreOrdinationPlaces = false
        currentState.isLoadingOrdinationPlaces = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            let result = try? await self.ordinationPlaceUseCase.loadPlaces(query: query, page: 1)
            guard token == self.ordinationRequestToken else { return }
            // Chỉ danh sách không lọc mới là "đã tải" — tìm kiếm lỗi không chặn lần mở sau.
            if query.isEmpty { self.hasLoadedOrdinationPlaces = result != nil }
            self.currentState.ordinationPlaceOptions += result?.items ?? []
            self.currentState.hasMoreOrdinationPlaces = result?.hasMore ?? false
            self.ordinationNextPage = (result?.page ?? 0) + 1
            self.currentState.isLoadingOrdinationPlaces = false
            self.stateSubject.send(.success(self.currentState))
        }
    }

    private func loadMoreOrdinationPlaces() {
        guard currentState.hasMoreOrdinationPlaces,
              !currentState.isLoadingOrdinationPlaces,
              !currentState.isLoadingMoreOrdinationPlaces else { return }
        currentState.isLoadingMoreOrdinationPlaces = true
        stateSubject.send(.success(currentState))

        let token = ordinationRequestToken
        let query = ordinationQuery
        let page = ordinationNextPage
        Task { [weak self] in
            guard let self else { return }
            let result = try? await self.ordinationPlaceUseCase.loadPlaces(query: query, page: page)
            guard token == self.ordinationRequestToken else { return }
            if let result {
                let known = Set(self.currentState.ordinationPlaceOptions.map(\.id))
                self.currentState.ordinationPlaceOptions += result.items.filter { !known.contains($0.id) }
                self.currentState.hasMoreOrdinationPlaces = result.hasMore
                self.ordinationNextPage = result.page + 1
            } else {
                // Lỗi mạng giữa chừng: dừng ở đây, cuộn lại hoặc mở lại bộ chọn sẽ thử lại.
                self.currentState.hasMoreOrdinationPlaces = true
            }
            self.currentState.isLoadingMoreOrdinationPlaces = false
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Các chùa người dùng vừa đề xuất, giữ ở đầu danh sách khi không có từ khoá hoặc khi tên khớp.
    private func proposedOrdinationPlaces(matching query: String) -> [ILOrdinationPlaceEntity] {
        let proposed = currentState.ordinationPlaceOptions.filter { $0.id.hasPrefix(Self.proposedIDPrefix) }
        guard !query.isEmpty else { return proposed }
        return proposed.filter { $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
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

        currentState.fullNameError = useCase.validateFullName(currentState.fullName)
        currentState.displayNameError = useCase.validateDisplayName(currentState.displayName)
        currentState.phoneNumberError = useCase.validatePhoneNumber(
            nationalDigits: currentState.nationalDigits,
            country: currentState.selectedCountry
        )
        currentState.emailError = useCase.validateEmail(currentState.email)
        currentState.passwordError = useCase.validatePassword(currentState.password)
        // EN: `ILDharmaNameSuggestionField` has no error line, so a dharma-name error is shown as an alert.
        // VI: `ILDharmaNameSuggestionField` không có dòng báo lỗi nên lỗi pháp danh hiện bằng alert.
        currentState.submitError = currentState.displayNameError

        guard !currentState.hasValidationError else {
            stateSubject.send(.success(currentState))
            return
        }

        currentState.isSubmitting = true
        stateSubject.send(.success(currentState))

        // Chùa còn chờ duyệt (`proposed-…`) chưa có id thật nên không gửi; server coi là chưa chọn.
        let ordinationTempleID = currentState.selectedOrdinationPlaceID
            .flatMap { $0.hasPrefix(Self.proposedIDPrefix) ? nil : $0 }
        let email = currentState.email.trimmingCharacters(in: .whitespacesAndNewlines)
        // EN: Request body per criterion 13 — `phone_country` + national digits (no E.164 rebuild),
        //     dharma name only when not empty.
        // VI: Body theo tiêu chí 13 — `phone_country` + phần số quốc gia (không tự dựng E.164),
        //     pháp danh chỉ gửi khi không rỗng.
        let entity = ILSignUpEntity(
            fullName: currentState.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: currentState.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            ordinationTempleID: ordinationTempleID,
            phoneCountry: currentState.selectedCountry.iso,
            phoneNumber: currentState.nationalDigits,
            email: email,
            password: currentState.password
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                let otp = try await self.useCase.sendVerificationCode(entity)
                self.currentState.isSubmitting = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.didRequestVerification(
                    email: email,
                    otpExpiresInSeconds: otp.expiresInSeconds,
                    resendAfterSeconds: otp.resendAfterSeconds
                ))
            } catch {
                // EN: Stay on SignUp with every value kept; a per-field error goes under its field,
                //     anything else is shown as an alert.
                // VI: Ở lại màn Đăng ký, giữ mọi giá trị; lỗi theo field hiện dưới field đó, còn lại
                //     hiện bằng alert.
                self.currentState.isSubmitting = false
                self.applySubmitError(error)
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    /// EN: Routes a server error to the field it belongs to (Error → UI table), else to `submitError`.
    /// VI: Đưa lỗi server về đúng field (bảng Error → UI), còn lại vào `submitError`.
    private func applySubmitError(_ error: Error) {
        let message = error.localizedDescription
        switch error as? ILSignUpError {
        case .phoneAlreadyRegistered?, .invalidPhone?:
            currentState.phoneNumberError = message
        case .invalidEmail?:
            currentState.emailError = message
        case .invalidPassword?:
            currentState.passwordError = message
        case .invalidFullName?:
            currentState.fullNameError = message
        case .invalidDharmaName?:
            currentState.displayNameError = message
            currentState.submitError = message
        default:
            currentState.submitError = message
        }
    }
}
