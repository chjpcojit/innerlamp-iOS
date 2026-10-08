//
//  ILLanguageUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILLanguageUseCase {
    func currentPreferences() -> ILLanguageEntity
    /// Persists the preferences. Theme is also applied to the live window right away.
    func apply(_ preferences: ILLanguageEntity)
}

final class ILLanguageUseCaseImpl: ILLanguageUseCase {

    private enum StorageKeys {
        static let language = "il_app_language"
        static let fontSize = "il_scripture_font_size"
    }

    private let userDefaultsService: UserDefaultsService
    private let themeService: ThemeService

    init(userDefaultsService: UserDefaultsService, themeService: ThemeService) {
        self.userDefaultsService = userDefaultsService
        self.themeService = themeService
    }

    func currentPreferences() -> ILLanguageEntity {
        ILLanguageEntity(
            language: userDefaultsService.load(key: StorageKeys.language, type: ILAppLanguage.self) ?? .vietnamese,
            fontSize: userDefaultsService.load(key: StorageKeys.fontSize, type: ILScriptureFontSize.self) ?? .medium,
            theme: Self.settingsTheme(for: themeService.currentMode)
        )
    }

    func apply(_ preferences: ILLanguageEntity) {
        userDefaultsService.save(key: StorageKeys.language, value: preferences.language)
        userDefaultsService.save(key: StorageKeys.fontSize, value: preferences.fontSize)
        themeService.setMode(Self.themeMode(for: preferences.theme))
    }

    // `ILSettingsThemeMode` (Domain) and `ILThemeMode` (Core/Theme, UIKit-facing) share raw values.
    private static func settingsTheme(for mode: ILThemeMode) -> ILSettingsThemeMode {
        ILSettingsThemeMode(rawValue: mode.rawValue) ?? .system
    }

    private static func themeMode(for theme: ILSettingsThemeMode) -> ILThemeMode {
        ILThemeMode(rawValue: theme.rawValue) ?? .system
    }
}
