//
//  ILEditProfileViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

/// The three rows of the "Hiển thị trong đạo tràng" group.
enum ILEditProfileVisibilityItem: Equatable {
    case streak
    case journal
    case offeringHistory
}

enum ILEditProfileNavEvent: Equatable {
    case goBack
    /// Profile saved successfully — leave the screen.
    case saved
    case changeAvatar
    case openVisibility(ILEditProfileVisibilityItem)
    case changePassword
    case deleteAccount
}

protocol ILEditProfileViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILEditProfileCoordinator` subscribes directly in
    /// `start()`, before the `ViewController`/`Input` exists.
    var navigationEventPublisher: AnyPublisher<ILEditProfileNavEvent, Never> { get }
}

final class ILEditProfileViewModel: ILEditProfileViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let saveTapped: AnyPublisher<Void, Never>
        let changeAvatarTapped: AnyPublisher<Void, Never>
        let displayNameChanged: AnyPublisher<String, Never>
        let templeNameChanged: AnyPublisher<String, Never>
        let bioChanged: AnyPublisher<String, Never>
        let visibilityTapped: AnyPublisher<ILEditProfileVisibilityItem, Never>
        let changePasswordTapped: AnyPublisher<Void, Never>
        let deleteAccountTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILEditProfileStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILEditProfileNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILEditProfileNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILEditProfileStateModel>, Never>
    private var profile: ILEditProfileEntity
    private var currentState: ILEditProfileStateModel
    private let useCase: ILEditProfileUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILEditProfileUseCase) {
        self.useCase = useCase
        let initialProfile = useCase.getProfile()
        self.profile = initialProfile
        let initialState = ILEditProfileViewModel.makeStateModel(profile: initialProfile)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.saveTapped
            .sink { [weak self] _ in self?.handleSave() }
            .store(in: &cancellables)

        input.changeAvatarTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.changeAvatar) }
            .store(in: &cancellables)

        input.displayNameChanged
            .sink { [weak self] value in self?.handleDisplayNameChanged(value) }
            .store(in: &cancellables)

        input.templeNameChanged
            .sink { [weak self] value in self?.handleTempleNameChanged(value) }
            .store(in: &cancellables)

        input.bioChanged
            .sink { [weak self] value in self?.handleBioChanged(value) }
            .store(in: &cancellables)

        input.visibilityTapped
            .sink { [weak self] item in self?.navigationEventSubject.send(.openVisibility(item)) }
            .store(in: &cancellables)

        input.changePasswordTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.changePassword) }
            .store(in: &cancellables)

        input.deleteAccountTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.deleteAccount) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        profile = useCase.getProfile()
        currentState = ILEditProfileViewModel.makeStateModel(profile: profile)
        stateSubject.send(.success(currentState))
    }

    private func handleDisplayNameChanged(_ value: String) {
        currentState.displayName = value
        currentState.initials = ILEditProfileViewModel.initials(of: value)
        // Clear the error as soon as the user starts fixing it; re-validated on save.
        currentState.displayNameError = nil
        stateSubject.send(.success(currentState))
    }

    private func handleTempleNameChanged(_ value: String) {
        currentState.templeName = value
        stateSubject.send(.success(currentState))
    }

    private func handleBioChanged(_ value: String) {
        currentState.bio = value
        stateSubject.send(.success(currentState))
    }

    private func handleSave() {
        guard !currentState.isSaving else { return }

        if let error = useCase.validateDisplayName(currentState.displayName) {
            currentState.displayNameError = ILEditProfileViewModel.message(for: error)
            stateSubject.send(.success(currentState))
            return
        }

        let edited = makeEditedProfile()
        currentState.displayNameError = nil
        currentState.isSaving = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.saveProfile(edited)
                self.profile = edited
                self.currentState.isSaving = false
                self.stateSubject.send(.success(self.currentState))
                self.navigationEventSubject.send(.saved)
            } catch {
                self.currentState.isSaving = false
                self.stateSubject.send(.failure(error))
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    // MARK: - StateModel -> Entity
    /// Applies the edited form fields onto the loaded profile (trimmed); read-only fields
    /// (phone, visibility) are carried over unchanged.
    private func makeEditedProfile() -> ILEditProfileEntity {
        var edited = profile
        edited.displayName = currentState.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.templeName = currentState.templeName.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.bio = currentState.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        return edited
    }

    // MARK: - Entity -> StateModel mapping
    /// Presentation-specific (initials, visibility labels) — lives here, not in a shared Mapper
    /// (see `references/data_layer_boundaries.md`).
    private static func makeStateModel(profile: ILEditProfileEntity) -> ILEditProfileStateModel {
        var model = ILEditProfileStateModel()
        model.initials = initials(of: profile.displayName)
        model.displayName = profile.displayName
        model.phoneNumber = profile.phoneNumber
        model.templeName = profile.templeName
        model.bio = profile.bio
        model.streakVisibilityTitle = visibilityTitle(profile.streakVisibility)
        model.journalVisibilityTitle = visibilityTitle(profile.journalVisibility)
        model.offeringHistoryVisibilityTitle = visibilityTitle(profile.offeringHistoryVisibility)
        return model
    }

    static func visibilityTitle(_ visibility: ILEditProfileVisibility) -> String {
        switch visibility {
        case .publicToSangha: return "editProfile.visibility.public".localized
        case .onlyMe: return "editProfile.visibility.onlyMe".localized
        case .anonymous: return "editProfile.visibility.anonymous".localized
        }
    }

    static func message(for error: ILEditProfileValidationError) -> String {
        switch error {
        case .displayNameRequired: return "editProfile.error.displayNameRequired".localized
        }
    }

    /// Avatar initials: first letter of the first and last words — "Diệu Tâm" → "DT",
    /// single word → 1 letter, empty → "".
    static func initials(of name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        guard let first = words.first?.first else { return "" }
        guard words.count > 1, let last = words.last?.first else { return String(first).uppercased() }
        return (String(first) + String(last)).uppercased()
    }
}
