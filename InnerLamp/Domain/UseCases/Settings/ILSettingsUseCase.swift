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

    init() {}

    func getSettings() -> ILSettingsEntity {
        // TODO: chưa có contract lưu trữ/API — thay dữ liệu mẫu bằng ILSettingsRepository khi có
        // contract (dùng il-data-layer-builder). Mọi toggle/giá trị dưới đây là mock khớp prototype.
        ILSettingsEntity(
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
            theme: .system,
            downloadsCount: 8,
            downloadsSizeMB: 412,
            hideJournalFromSangha: false,
            appVersion: "1.4"
        )
    }
}
