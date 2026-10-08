//
//  ILLanguageStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the Language & display screen, owned by `ILLanguageViewModel`. No UIKit import:
/// the view maps `previewFontIndex` to `ILTypography.languagePreviewFonts`.
struct ILLanguageStateModel: Equatable {

    struct LanguageOption: Equatable {
        let language: ILAppLanguage
        let title: String
        let subtitle: String
        let isSelected: Bool
    }

    struct FontSizeOption: Equatable {
        let fontSize: ILScriptureFontSize
        let title: String
        let isSelected: Bool
    }

    struct ThemeOption: Equatable {
        let theme: ILSettingsThemeMode
        let title: String
        let isSelected: Bool
    }

    var languageOptions: [LanguageOption] = []
    var fontSizeOptions: [FontSizeOption] = []
    var themeOptions: [ThemeOption] = []
    var previewText: String = ""
    var previewFontIndex: Int = 1

    static let initial = ILLanguageStateModel()
}
