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
    var headerTitle: String = ""
    /// "N tràng" — số tràng đã niệm đủ.
    var headerSubtitle: String = ""

    var count: Int = 0
    var goal: Int = 108
    /// "/ 108"
    var goalText: String = ""

    var mantraText: String = ""
    var hintText: String = ""
    var strandAccessibilityLabel: String = ""
    var resetTitle: String = ""
    var doneTitle: String = ""
    var footnoteText: String = ""

    /// Mốc vừa chạm ở lần đếm gần nhất (rung nhẹ / chuông); `nil` nếu lần cập nhật này không phải
    /// một lần đếm chạm mốc (khởi tạo, "Bắt đầu lại", hạt thường).
    var milestone: ILMalaMilestone?

    static let initial = ILMalaStateModel()
}
