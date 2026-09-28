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

/// 1 thẻ Phật / Bồ Tát trong lưới 2 cột — bản sao presentation của `ILDeityEntity` với nhãn loại,
/// dòng đức hạnh cốt lõi và chuỗi ngày vía đã format sẵn cho view.
struct ILDeitiesItemModel: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    /// "Phật" / "Bồ Tát" — hiện trên badge của ô ảnh.
    let kindLabel: String
    let name: String
    /// Dòng mô tả ngắn (đức hạnh cốt lõi).
    let role: String
    /// "Vía 15/04 âm lịch" — rỗng thì ẩn.
    let memorialText: String
}

/// UI state cho màn danh sách "Chư Phật & Bồ Tát" — Presentation layer, do `ILDeitiesViewModel`
/// sở hữu và cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để
/// hiển thị. Nhãn UI (`.localized`) và chuỗi đã format nằm ở đây; dữ liệu nội dung thô nằm trên
/// `ILDeityEntity` (xem `references/data_layer_boundaries.md`).
struct ILDeitiesStateModel: Equatable {
    /// Phụ đề header ("18 vị · tiểu sử, đại nguyện, thần chú") đã format sẵn.
    var subtitle: String = ""
    var filters: [ILDeitiesFilterModel] = []
    var items: [ILDeitiesItemModel] = []

    static let initial = ILDeitiesStateModel()
}
