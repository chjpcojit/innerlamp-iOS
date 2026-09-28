//
//  ILSettingsStateModel.swift
//  InnerLamp
//

import Foundation

/// Trạng thái UI của màn Cài đặt — do `ILSettingsViewModel` sở hữu, `ViewController` chỉ đọc để
/// render. Không import UIKit, không có logic nghiệp vụ. Mọi chuỗi đã format (giờ chuông, tóm tắt
/// tải về, nhãn theme...) nằm ở đây, không nằm trên `ILSettingsEntity`.
struct ILSettingsStateModel: Equatable {
    // Thẻ tài khoản đầu màn
    var accountInitial: String = ""
    var accountName: String = ""
    var accountSubtitle: String = ""

    // Thời khóa
    var bellEnabled: Bool = true
    var bellScheduleText: String = ""
    var fastDayReminderEnabled: Bool = true
    var bellSoundTitle: String = ""

    // Hiển thị & ngôn ngữ
    var scriptureFontScale: Double = 0.62
    var bilingualEnabled: Bool = false
    var themeTitle: String = ""

    // Nội dung & trợ giúp
    var downloadsSummary: String = ""
    var languageSummary: String = ""

    // Riêng tư
    var hideJournalFromSangha: Bool = false

    // Footer
    var versionText: String = ""

    static let initial = ILSettingsStateModel()
}
