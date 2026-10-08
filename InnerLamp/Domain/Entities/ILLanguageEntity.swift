//
//  ILLanguageEntity.swift
//  InnerLamp
//

import Foundation

/// App languages the user can pick on the Language screen. Raw values are the language codes
/// used by the localization files (`Resources/Localization/<code>.json`).
enum ILAppLanguage: String, Codable, CaseIterable, Equatable {
    case vietnamese = "vi"
    case english = "en"
    case traditionalChinese = "zh-Hant"
}

/// 4 sutra font-size presets (Nhỏ / Vừa / Lớn / Rất lớn). The raw value is the preset index.
enum ILScriptureFontSize: Int, Codable, CaseIterable, Equatable {
    case small = 0
    case medium = 1
    case large = 2
    case extraLarge = 3
}

/// The user's display preferences — pure business values, no UI strings or fonts.
struct ILLanguageEntity: Equatable {
    var language: ILAppLanguage = .vietnamese
    var fontSize: ILScriptureFontSize = .medium
    var theme: ILSettingsThemeMode = .system
}
