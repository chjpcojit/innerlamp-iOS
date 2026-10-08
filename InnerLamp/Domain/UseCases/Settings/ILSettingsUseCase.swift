//
//  ILSettingsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSettingsUseCase {
    /// Trả về cài đặt hiện tại. Hiện là dữ liệu mẫu vì chưa có contract lưu trữ/API được xác nhận —
    /// khi có Repository thật sẽ thay bằng `ILSettingsRepository` (dùng il-data-layer-builder).
    func getSettings() -> ILSettingsEntity
}

final class ILSettingsUseCaseImpl: ILSettingsUseCase {

    private let languageUseCase: ILLanguageUseCase

    init(languageUseCase: ILLanguageUseCase) {
        self.languageUseCase = languageUseCase
    }

    func getSettings() -> ILSettingsEntity {
        // Display preferences (theme / language / font size) are real; the rest stays mock below.
        let display = languageUseCase.currentPreferences()

        // TODO: chưa có contract lưu trữ/API — thay dữ liệu mẫu bằng ILSettingsRepository khi có
        // contract (dùng il-data-layer-builder). Mọi toggle/giá trị dưới đây là mock khớp prototype.
        return ILSettingsEntity(
            account: ILSettingsAccountEntity(
                fullName: "settings.mock.fullName".localized,
                dharmaName: "settings.mock.dharmaName".localized,
                phoneNumber: "settings.mock.phone".localized
            ),
            bellEnabled: true,
            bellTimes: [
                ILSettingsBellEntity(hour: 5, minute: 30),
                ILSettingsBellEntity(hour: 12, minute: 0),
                ILSettingsBellEntity(hour: 21, minute: 30)
            ],
            fastDayReminderEnabled: true,
            bellSound: .bronzeBell,
            scriptureFontScale: 0.62,
            bilingualEnabled: false,
            theme: display.theme,
            language: display.language,
            scriptureFontSize: display.fontSize,
            downloadsCount: 8,
            downloadsSizeMB: 412,
            hideJournalFromSangha: false,
            appVersion: "1.4"
        )
    }
}
