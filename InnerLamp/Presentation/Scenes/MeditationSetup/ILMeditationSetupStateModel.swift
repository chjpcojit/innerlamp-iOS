//
//  ILMeditationSetupStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// UI state cho màn Chuẩn bị thiền — Presentation layer, do `ILMeditationSetupViewModel` sở hữu và
/// cập nhật độc quyền thông qua `applyEntity(_:)`. Không UIKit, không business logic — ViewController
/// chỉ đọc để hiển thị. Chứa các chuỗi `.localized` đã resolve và giá trị đã format, khác với số liệu
/// thô nằm trên `ILMeditationSetupEntity` (xem `references/data_layer_boundaries.md`).
struct ILMeditationSetupStateModel: Equatable {
    var headerTitle: String = ""
    var title: String = ""
    var subtitle: String = ""

    var durationSectionTitle: String = ""
    /// Các mức thời lượng (phút) — hiển thị nguyên dạng số ("5", "12", ...).
    var durationOptions: [Int] = []
    /// Index của thời lượng đang chọn trong `durationOptions`.
    var selectedDurationIndex: Int = 0
    var durationHint: String = ""

    var bellSectionTitle: String = ""
    var openingBellTitle: String = ""
    var openingBellValue: String = ""
    var intervalBellTitle: String = ""
    var intervalBellValue: String = ""
    var backgroundSoundTitle: String = ""
    var backgroundSoundValue: String = ""

    var tipText: String = ""
    /// "Bắt đầu · N phút" — theo thời lượng đang chọn.
    var startButtonTitle: String = ""
    var silentButtonTitle: String = ""

    static let initial = ILMeditationSetupStateModel()
}
