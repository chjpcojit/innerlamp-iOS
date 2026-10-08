//
//  ILMalaStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state cho màn Tràng hạt — Presentation layer, do `ILMalaViewModel` sở hữu và cập nhật độc
/// quyền thông qua `applyEntity(_:)`. Không UIKit, không business logic — `ViewController` chỉ đọc
/// để hiển thị. Chứa các chuỗi `.localized` tĩnh (nhãn UI) và giá trị đã format, khác với số liệu
/// thô nằm trên `ILMalaEntity` (xem `references/data_layer_boundaries.md`).
struct ILMalaStateModel: Equatable {
    /// Một lựa chọn mục tiêu ("21 biến"...) trên hàng chip.
    struct GoalOption: Equatable {
        let value: Int
        let title: String
        let isSelected: Bool
    }

    var headerTitle: String = ""
    /// "Vòng 1 · biến 27 / 108"
    var headerSubtitle: String = ""
    /// Nút "Xong" bên phải header.
    var doneTitle: String = ""

    var count: Int = 0
    var goal: Int = 108
    var goalOptions: [GoalOption] = []

    var mantraText: String = ""
    var strandAccessibilityLabel: String = ""
    var resetTitle: String = ""

    /// Popup "Tròn N biến" hiện khi đủ `goal` biến.
    var isRoundComplete: Bool = false
    var completionTitle: String = ""
    var completionMessage: String = ""
    var continueTitle: String = ""

    /// Mốc vừa chạm ở lần đếm gần nhất (rung nhẹ / chuông); `nil` nếu lần cập nhật này không phải
    /// một lần đếm chạm mốc (khởi tạo, "Bắt đầu lại", hạt thường).
    var milestone: ILMalaMilestone?

    static let initial = ILMalaStateModel()
}
