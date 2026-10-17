//
//  ILFestivalsEntity.swift
//  InnerLamp
//

import Foundation

/// Loại ngày trong màn "Lịch lễ Phật giáo" — quyết định tông màu nhấn của số ngày.
enum ILFestivalKind: Equatable {
    /// Ngày lễ / vía có tên, lấy từ server (`GET /v1/calendar/events`) — nhấn màu.
    case festival
    /// Rằm / Mùng Một ("ngày trai giới", `recurrence == lunar_monthly`) — chữ thường. Từ server.
    case observance
}

/// 1 ngày lễ Phật giáo (hoặc ngày trai giới) trong màn "Lịch lễ Phật giáo" — nội dung nghiệp vụ
/// thô: ngày dương, tên lễ, loại ngày và số ngày còn lại. Chuỗi hiển thị ("Hôm nay", "còn N
/// ngày"…) do `ILFestivalsViewModel` format khi map sang `ILFestivalsStateModel`.
struct ILFestivalDayEntity: Equatable, Identifiable {
    /// id ổn định = ngày dương `yyyy-MM-dd`, kèm `-<eventCode>` với ngày lễ (một ngày có thể có
    /// nhiều lễ).
    let id: String
    /// Ngày dương lịch ngày lễ diễn ra.
    let date: Date
    /// Tên lễ — `name` của sự kiện từ server.
    let title: String
    let kind: ILFestivalKind
    /// Số ngày còn lại kể từ hôm nay (0 = hôm nay, 1 = ngày mai, N = còn N ngày).
    let daysUntil: Int
    /// Ngày âm lịch của `date` — lấy từ server.
    let lunarDay: Int
    let lunarMonth: Int
    let isLeapMonth: Bool
    /// Mã sự kiện trên server — `nil` với ngày trai giới (không có trang chi tiết).
    var eventCode: String? = nil
    /// BR-CAL-10: "Lễ lớn" do server đánh dấu — chip "Lễ lớn" lọc theo cờ này.
    var isMajor: Bool = false
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
/// Chứa dữ liệu nghiệp vụ thô: ngày dương, loại ngày (`ILFestivalKind`) và số ngày còn lại
/// (`daysUntil`). `title`/`label` là nội dung
/// (tên lễ / nhãn tháng) đã resolve tại UseCase — khớp `ILHomeEventMonthEntity.monthLabel`. Chuỗi hiển thị thuần (countdown "Hôm nay"/"còn N ngày",
/// thứ ngày, phụ đề âm lịch) nằm ở `ILFestivalsStateModel`
/// (`Presentation/Scenes/Festivals/ILFestivalsStateModel.swift`), do `ILFestivalsViewModel` format.
/// Xem `references/data_layer_boundaries.md`.
struct ILFestivalsEntity: Equatable {
    var months: [ILFestivalMonthEntity] = []

    static let empty = ILFestivalsEntity()
}
