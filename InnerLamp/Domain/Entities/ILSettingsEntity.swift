//
//  ILSettingsEntity.swift
//  InnerLamp
//

import Foundation

/// 3 lựa chọn giao diện cho hàng "Chế độ tối" — ánh xạ 1-1 với state `theme` (0/1/2) trong design
/// handoff. Đặt ở Domain (không import UIKit) để ViewModel test được mà không chạy UIKit.
/// Lưu ý: giá trị thật do `ILThemeMode` (Core/Theme) + `ThemeService` quản lý; enum Domain này chỉ
/// mô tả giá trị cài đặt cho màn Cài đặt, sẽ đồng bộ với `ThemeService` khi màn `lang` được build.
enum ILSettingsThemeMode: Int, Equatable {
    case system = 0
    case light = 1
    case dark = 2
}

/// Âm thanh tiếng chuông có thể chọn. Prototype mới chỉ có 1 lựa chọn.
enum ILSettingsBellSound: Equatable {
    case bronzeBell
}

/// Một mốc giờ chuông tỉnh thức (giờ + phút).
struct ILSettingsBellEntity: Equatable {
    let hour: Int
    let minute: Int
}

/// Tài khoản hiển thị ở thẻ đầu màn Cài đặt (tên, pháp danh, số điện thoại).
struct ILSettingsAccountEntity: Equatable {
    var fullName: String = ""
    var dharmaName: String = ""
    var phoneNumber: String = ""
}

/// Cài đặt của người dùng — chỉ dữ liệu nghiệp vụ, không có trạng thái UI hay chuỗi đã format.
/// Mọi chuỗi hiển thị / định dạng số thuộc về `ILSettingsStateModel` (Presentation).
struct ILSettingsEntity: Equatable {
    // Thẻ tài khoản đầu màn
    var account = ILSettingsAccountEntity()

    // Thời khóa
    var bellEnabled: Bool = true
    var bellTimes: [ILSettingsBellEntity] = []
    var fastDayReminderEnabled: Bool = true
    var bellSound: ILSettingsBellSound = .bronzeBell

    // Hiển thị & ngôn ngữ
    var scriptureFontScale: Double = 0.62
    var bilingualEnabled: Bool = false
    var theme: ILSettingsThemeMode = .system

    // Nội dung & trợ giúp
    var downloadsCount: Int = 8
    var downloadsSizeMB: Int = 412

    // Riêng tư
    var hideJournalFromSangha: Bool = false

    var appVersion: String = "1.4"

    static let empty = ILSettingsEntity()
}
