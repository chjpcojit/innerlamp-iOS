//
//  ILLanguageViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLanguageNavEvent: Equatable {
    case goBack
}

protocol ILLanguageViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILLanguageCoordinator` subscribes in `start()`,
    /// before the `ViewController`/`Input` exist.
    var navigationEventPublisher: AnyPublisher<ILLanguageNavEvent, Never> { get }
}

final class ILLanguageViewModel: ILLanguageViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let languageSelected: AnyPublisher<ILAppLanguage, Never>
        let fontSizeSelected: AnyPublisher<ILScriptureFontSize, Never>
        let themeSelected: AnyPublisher<ILSettingsThemeMode, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLanguageStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLanguageNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLanguageNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILLanguageStateModel>, Never>
    private var preferences: ILLanguageEntity
    private let useCase: ILLanguageUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILLanguageUseCase) {
        self.useCase = useCase
        let initialPreferences = useCase.currentPreferences()
        self.preferences = initialPreferences
        self.stateSubject = CurrentValueSubject(
            .success(ILLanguageViewModel.makeStateModel(preferences: initialPreferences))
        )
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.languageSelected
            .sink { [weak self] language in self?.update { $0.language = language } }
            .store(in: &cancellables)

        input.fontSizeSelected
            .sink { [weak self] fontSize in self?.update { $0.fontSize = fontSize } }
            .store(in: &cancellables)

        input.themeSelected
            .sink { [weak self] theme in self?.update { $0.theme = theme } }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        preferences = useCase.currentPreferences()
        stateSubject.send(.success(ILLanguageViewModel.makeStateModel(preferences: preferences)))
    }

    /// Every selection is applied immediately (theme re-skins the app live) — there is no Save button.
    private func update(_ change: (inout ILLanguageEntity) -> Void) {
        var updated = preferences
        change(&updated)
        guard updated != preferences else { return }
        preferences = updated
        useCase.apply(updated)
        stateSubject.send(.success(ILLanguageViewModel.makeStateModel(preferences: updated)))
    }

    // MARK: - Entity -> StateModel mapping
    private static func makeStateModel(preferences: ILLanguageEntity) -> ILLanguageStateModel {
        var model = ILLanguageStateModel()
        model.languageOptions = ILAppLanguage.allCases.map {
            ILLanguageStateModel.LanguageOption(
                language: $0,
                title: languageTitle($0),
                subtitle: languageSubtitle($0),
                isSelected: $0 == preferences.language
            )
        }
        model.fontSizeOptions = ILScriptureFontSize.allCases.map {
            ILLanguageStateModel.FontSizeOption(
                fontSize: $0,
                title: fontSizeTitle($0),
                isSelected: $0 == preferences.fontSize
            )
        }
        model.themeOptions = [ILSettingsThemeMode.light, .dark, .system].map {
            ILLanguageStateModel.ThemeOption(
                theme: $0,
                title: ILSettingsViewModel.themeTitle($0),
                isSelected: $0 == preferences.theme
            )
        }
        model.previewText = "language.preview.sample".localized
        model.previewFontIndex = preferences.fontSize.rawValue
        return model
    }

    static func languageTitle(_ language: ILAppLanguage) -> String {
        switch language {
        case .vietnamese: return "language.option.vi.title".localized
        case .english: return "language.option.en.title".localized
        case .traditionalChinese: return "language.option.zhHant.title".localized
        }
    }

    private static func languageSubtitle(_ language: ILAppLanguage) -> String {
        switch language {
        case .vietnamese: return "language.option.vi.subtitle".localized
        case .english: return "language.option.en.subtitle".localized
        case .traditionalChinese: return "language.option.zhHant.subtitle".localized
        }
    }

    static func fontSizeTitle(_ fontSize: ILScriptureFontSize) -> String {
        switch fontSize {
        case .small: return "language.fontSize.small".localized
        case .medium: return "language.fontSize.medium".localized
        case .large: return "language.fontSize.large".localized
        case .extraLarge: return "language.fontSize.extraLarge".localized
        }
    }
}
