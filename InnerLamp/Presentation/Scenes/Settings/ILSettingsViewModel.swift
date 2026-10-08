//
//  ILSettingsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSettingsNavEvent: Equatable {
    case goBack
    case openProfile
    case openBellSound
    case openDarkMode
    case openDownloads
    case openLanguage
    case openHelp
    case openExportData
    case openOffline
}

protocol ILSettingsViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILSettingsCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILSettingsNavEvent, Never> { get }
}

final class ILSettingsViewModel: ILSettingsViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let viewWillAppear: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let profileTapped: AnyPublisher<Void, Never>
        let bellToggleChanged: AnyPublisher<Bool, Never>
        let fastDayToggleChanged: AnyPublisher<Bool, Never>
        let bellSoundTapped: AnyPublisher<Void, Never>
        let fontScaleChanged: AnyPublisher<Double, Never>
        let bilingualToggleChanged: AnyPublisher<Bool, Never>
        let darkModeTapped: AnyPublisher<Void, Never>
        let downloadsTapped: AnyPublisher<Void, Never>
        let languageTapped: AnyPublisher<Void, Never>
        let helpTapped: AnyPublisher<Void, Never>
        let hideJournalToggleChanged: AnyPublisher<Bool, Never>
        let exportDataTapped: AnyPublisher<Void, Never>
        let offlineTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSettingsStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSettingsNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSettingsNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILSettingsStateModel>, Never>
    private var settings: ILSettingsEntity
    private var currentState: ILSettingsStateModel
    private let useCase: ILSettingsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSettingsUseCase) {
        self.useCase = useCase
        let initialSettings = useCase.getSettings()
        self.settings = initialSettings
        let initialState = ILSettingsViewModel.makeStateModel(settings: initialSettings)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.viewWillAppear
            .sink { [weak self] _ in self?.handleViewWillAppear() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.profileTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openProfile) }
            .store(in: &cancellables)

        input.bellToggleChanged
            .sink { [weak self] value in self?.handleBellToggle(value) }
            .store(in: &cancellables)

        input.fastDayToggleChanged
            .sink { [weak self] value in self?.handleFastDayToggle(value) }
            .store(in: &cancellables)

        input.bellSoundTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openBellSound) }
            .store(in: &cancellables)

        input.fontScaleChanged
            .sink { [weak self] value in self?.handleFontScaleChanged(value) }
            .store(in: &cancellables)

        input.bilingualToggleChanged
            .sink { [weak self] value in self?.handleBilingualToggle(value) }
            .store(in: &cancellables)

        input.darkModeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDarkMode) }
            .store(in: &cancellables)

        input.downloadsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDownloads) }
            .store(in: &cancellables)

        input.languageTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openLanguage) }
            .store(in: &cancellables)

        input.helpTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openHelp) }
            .store(in: &cancellables)

        input.hideJournalToggleChanged
            .sink { [weak self] value in self?.handleHideJournalToggle(value) }
            .store(in: &cancellables)

        input.exportDataTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openExportData) }
            .store(in: &cancellables)

        input.offlineTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openOffline) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        settings = useCase.getSettings()
        currentState = ILSettingsViewModel.makeStateModel(settings: settings)
        stateSubject.send(.success(currentState))
    }

    /// Returning from the Language screen: re-read only the display summaries (theme / language /
    /// font size) so unsaved mock toggles on this screen are not reset.
    private func handleViewWillAppear() {
        settings = useCase.getSettings()
        var updated = currentState
        updated.themeTitle = ILSettingsViewModel.themeTitle(settings.theme)
        updated.languageSummary = ILSettingsViewModel.languageSummary(settings)
        guard updated != currentState else { return }
        currentState = updated
        stateSubject.send(.success(currentState))
    }

    private func handleBellToggle(_ value: Bool) {
        currentState.bellEnabled = value
        stateSubject.send(.success(currentState))
    }

    private func handleFastDayToggle(_ value: Bool) {
        currentState.fastDayReminderEnabled = value
        stateSubject.send(.success(currentState))
    }

    private func handleFontScaleChanged(_ value: Double) {
        currentState.scriptureFontScale = value
        stateSubject.send(.success(currentState))
    }

    private func handleBilingualToggle(_ value: Bool) {
        currentState.bilingualEnabled = value
        stateSubject.send(.success(currentState))
    }

    private func handleHideJournalToggle(_ value: Bool) {
        currentState.hideJournalFromSangha = value
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (format giờ chuông, nhãn theme, chữ đầu tên...) nên nằm ở đây,
    /// không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(settings: ILSettingsEntity) -> ILSettingsStateModel {
        var model = ILSettingsStateModel()

        model.accountInitial = initial(of: settings.account.fullName)
        model.accountName = settings.account.fullName
        model.accountSubtitle = makeAccountSubtitle(settings.account)

        model.bellEnabled = settings.bellEnabled
        model.bellScheduleText = settings.bellTimes
            .map { String(format: "%02d:%02d", $0.hour, $0.minute) }
            .joined(separator: " · ")
        model.fastDayReminderEnabled = settings.fastDayReminderEnabled
        model.bellSoundTitle = bellSoundTitle(settings.bellSound)

        model.scriptureFontScale = settings.scriptureFontScale
        model.bilingualEnabled = settings.bilingualEnabled
        model.themeTitle = themeTitle(settings.theme)

        model.downloadsSummary = String(
            format: "settings.row.downloads.sub".localized,
            settings.downloadsCount,
            settings.downloadsSizeMB
        )
        model.languageSummary = languageSummary(settings)

        model.hideJournalFromSangha = settings.hideJournalFromSangha

        model.versionText = String(format: "settings.footer.version".localized, settings.appVersion)
        return model
    }

    /// "Pháp danh Tâm Minh · +84 912 345 678"; chưa có pháp danh thì chỉ còn vai trò.
    private static func makeAccountSubtitle(_ account: ILSettingsAccountEntity) -> String {
        guard !account.dharmaName.isEmpty else {
            return "settings.account.role.fallback".localized
        }
        return String(
            format: "settings.account.subtitle".localized,
            account.dharmaName,
            account.phoneNumber
        )
    }

    /// "Tiếng Việt · cỡ chữ vừa"
    static func languageSummary(_ settings: ILSettingsEntity) -> String {
        String(
            format: "settings.row.language.sub".localized,
            ILLanguageViewModel.languageTitle(settings.language),
            ILLanguageViewModel.fontSizeTitle(settings.scriptureFontSize).lowercased()
        )
    }

    static func bellSoundTitle(_ sound: ILSettingsBellSound) -> String {
        switch sound {
        case .bronzeBell: return "settings.bellSound.bronzeBell".localized
        }
    }

    static func themeTitle(_ mode: ILSettingsThemeMode) -> String {
        switch mode {
        case .system: return "settings.theme.system".localized
        case .light: return "settings.theme.light".localized
        case .dark: return "settings.theme.dark".localized
        }
    }

    /// Chữ cái đầu của tên gọi (từ cuối) — "Nguyễn Bình An" → "A".
    static func initial(of name: String) -> String {
        guard let lastWord = name.split(separator: " ").last, let first = lastWord.first else { return "" }
        return String(first).uppercased()
    }
}
