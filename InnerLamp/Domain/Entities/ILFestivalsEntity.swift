//
//  ILFestivalsEntity.swift
//  InnerLamp
//

import Foundation

/// Loại ngày lễ trong màn "Lịch lễ Phật giáo" — quyết định tông màu nhấn và danh sách chùa tổ
/// chức. Khớp phân loại trong design handoff (`InnerLamp Prototype.dc.html`, `festVals`):
/// lễ lớn (BIG) do cả 9 chùa tổ chức, vía khác do Từ Quang + 2 chùa, còn Rằm/Mùng Một ("ngày
/// trai giới") chỉ do Từ Quang.
enum ILFestivalKind: Equatable {
    /// Lễ lớn (vía, Phật Đản, Vu Lan…) — nhấn màu, cả 9 chùa tổ chức.
    case major
    /// Vía khác — nhấn màu, Từ Quang + 2 chùa tổ chức.
    case festival
    /// Rằm / Mùng Một (ngày trai giới) — chữ thường, chỉ Từ Quang tổ chức.
    case observance
}

/// 1 ngày lễ Phật giáo (hoặc ngày trai giới) trong màn "Lịch lễ Phật giáo" — nội dung nghiệp vụ
/// thô: ngày dương, tên lễ, loại ngày, số ngày còn lại và các chùa tổ chức (theo id). Chuỗi hiển
/// thị ("Hôm nay", "còn N ngày", tên chùa…) do `ILFestivalsViewModel` format khi map sang
/// `ILFestivalsStateModel`.
struct ILFestivalDayEntity: Equatable, Identifiable {
    /// id ổn định = ngày dương `yyyy-MM-dd`.
    let id: String
    /// Ngày dương lịch ngày lễ diễn ra.
    let date: Date
    /// Tên lễ (đã resolve) — tên lễ từ catalog hoặc "Rằm/Mùng Một tháng X — ngày trai giới".
    let title: String
    let kind: ILFestivalKind
    /// Số ngày còn lại kể từ hôm nay (0 = hôm nay, 1 = ngày mai, N = còn N ngày).
    let daysUntil: Int
    /// Các chùa tổ chức ngày lễ này (theo id).
    let hostTempleIDs: [String]
}

/// 1 tháng dương trong màn "Lịch lễ Phật giáo" — các ngày lễ gom theo tháng dương lịch.
struct ILFestivalMonthEntity: Equatable, Identifiable {
    /// id ổn định = tháng dương `yyyy-MM`.
    let id: String
    /// Nhãn tháng ("Tháng 9" hoặc "Tháng 9, 2027" khi khác năm hiện tại).
    let label: String
    let days: [ILFestivalDayEntity]
}

/// Pure business entity cho màn "Lịch lễ Phật giáo" — Domain layer only.
///
/// Chứa dữ liệu nghiệp vụ thô: ngày dương, loại ngày (`ILFestivalKind`), số ngày còn lại
/// (`daysUntil`), và các chùa tổ chức theo id (`hostTempleIDs`). `title`/`label` là nội dung
/// (tên lễ / nhãn tháng) đã resolve tại UseCase — khớp `ILHomeEventMonthEntity.monthLabel` và
/// `ILBuddhistEventTemplateEntity.title`. Chuỗi hiển thị thuần (countdown "Hôm nay"/"còn N ngày",
/// tên chùa đã `.localized`, thứ ngày, phụ đề âm lịch) nằm ở `ILFestivalsStateModel`
/// (`Presentation/Scenes/Festivals/ILFestivalsStateModel.swift`), do `ILFestivalsViewModel` format.
/// Xem `references/data_layer_boundaries.md`.
struct ILFestivalsEntity: Equatable {
    var months: [ILFestivalMonthEntity] = []

    static let empty = ILFestivalsEntity()
}
