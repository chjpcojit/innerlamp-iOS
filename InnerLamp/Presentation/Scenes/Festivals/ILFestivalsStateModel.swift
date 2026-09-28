//
//  ILFestivalsStateModel.swift
//  InnerLamp
//

import Foundation

/// Tab lọc của màn "Lịch lễ Phật giáo".
enum ILFestivalsTab: Int, Equatable, CaseIterable {
    case all = 0
    /// "Lễ lớn" — mọi ngày lễ có tên (lễ lớn + vía), bỏ ngày trai giới.
    case festivals
    /// "Rằm & Mùng Một" — chỉ các ngày trai giới.
    case observances
}

/// 1 chùa tổ chức (chip bấm mở Trang chùa) — tên đã `.localized`.
struct ILFestivalHostModel: Equatable, Identifiable {
    let id: String
    let name: String
}

/// 1 ngày lễ đã sẵn sàng hiển thị — chuỗi countdown/thứ ngày/phụ đề đã format, cờ màu đã tính.
struct ILFestivalDayModel: Equatable, Identifiable {
    let id: String
    /// "05" (ngày dương, 2 chữ số).
    let dayNumber: String
    /// "CN" / "T2"…"T7".
    let weekdayLabel: String
    let title: String
    /// "Hôm nay" / "Ngày mai" / "còn N ngày".
    let countdownText: String
    /// `true` khi là lễ có tên (tô màu nhấn số ngày), `false` với ngày trai giới.
    let isFestival: Bool
    /// `true` khi countdown là "Hôm nay"/"Ngày mai" (tô màu nhấn chữ đếm ngược).
    let isImminent: Bool
    /// `true` khi diễn ra hôm nay (viền vàng thẻ).
    let isToday: Bool
    /// "Thứ X, dd-MM · Âm lịch dd-mm (nhuận) · N chùa tổ chức".
    let lunarSubtitle: String
    let hosts: [ILFestivalHostModel]
    /// "+N chùa" khi có nhiều hơn 3 chùa tổ chức, `nil` ngược lại.
    let moreHostsText: String?
}

/// 1 tháng dương đã sẵn sàng hiển thị.
struct ILFestivalMonthModel: Equatable, Identifiable {
    let id: String
    let label: String
    let days: [ILFestivalDayModel]
}

/// UI state cho màn "Lịch lễ Phật giáo" — Presentation layer, do `ILFestivalsViewModel` sở hữu,
/// `ViewController` chỉ đọc để render. Không UIKit, không business logic.
struct ILFestivalsStateModel: Equatable {
    var selectedTab: ILFestivalsTab = .all
    /// "12 tháng tới · N ngày".
    var subtitle: String = ""
    var months: [ILFestivalMonthModel] = []

    var isEmpty: Bool { months.isEmpty }

    static let initial = ILFestivalsStateModel()
}
