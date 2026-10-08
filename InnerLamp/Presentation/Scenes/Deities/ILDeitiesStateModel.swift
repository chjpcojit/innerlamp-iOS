//
//  ILDeitiesStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chip lọc trên header màn "Chư Phật & Bồ Tát". `kind == nil` là "Tất cả".
struct ILDeitiesFilterModel: Equatable, Identifiable {
    let id: String
    let label: String
    let kind: ILDeityKind?
    let isSelected: Bool
}

/// 1 thẻ Phật / Bồ Tát trong lưới 2 cột — bản sao presentation của `ILDeitySummaryEntity` với nhãn
/// loại, dòng đức hạnh cốt lõi và dòng ngày vía đã format sẵn cho view.
struct ILDeitiesItemModel: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    /// "Phật" / "Bồ Tát" — hiện trên badge của ô ảnh.
    let kindLabel: String
    let name: String
    /// Dòng mô tả ngắn (đức hạnh cốt lõi).
    let role: String
    /// "Vía 15/04 âm lịch" — the server summary has no memorial days yet, so this is the
    /// "updating" placeholder for now. Empty hides the line.
    let memorialText: String
    /// Raw server thumbnail URL; empty/`nil` shows the placeholder.
    var thumbnailURL: String? = nil
}

/// UI state cho màn danh sách "Chư Phật & Bồ Tát" — Presentation layer, do `ILDeitiesViewModel`
/// sở hữu và cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để
/// hiển thị. Nhãn UI (`.localized`) và chuỗi đã format nằm ở đây; dữ liệu nội dung thô nằm trên
/// `ILDeitySummaryEntity` (xem `references/data_layer_boundaries.md`).
struct ILDeitiesStateModel: Equatable {
    /// Phụ đề header ("18 vị · tiểu sử, đại nguyện, thần chú"), hoặc "Đang cập nhật" khi server
    /// không có vị nào.
    var subtitle: String = ""
    var filters: [ILDeitiesFilterModel] = []
    var items: [ILDeitiesItemModel] = []
    /// Empty-state copy shown instead of the grid when `items` is empty ("Đang cập nhật"); both
    /// empty when there are items.
    var emptyTitle: String = ""
    var emptyMessage: String = ""

    static let initial = ILDeitiesStateModel()
}
