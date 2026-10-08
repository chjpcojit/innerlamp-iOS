//
//  ILMemorialStateModel.swift
//  InnerLamp
//

import Foundation

/// The soonest entry, shown as the large card on top of the list.
struct ILMemorialHighlightModel: Equatable {
    let id: String
    let eyebrow: String
    let name: String
    /// "Ông nội · Giỗ lần thứ 5"
    let relationLine: String
    /// "15 tháng Chạp âm lịch"
    let dateLine: String
    /// "Thứ Bảy, 15/11/2026"
    let whenLine: String
    let remindLine: String
}

/// 1 row of "THEO NGÀY GIỖ SẮP TỚI".
struct ILMemorialRowModel: Equatable, Identifiable {
    let id: String
    let name: String
    /// "Ông nội · 15 tháng Chạp âm lịch"
    let subtitle: String
    let daysText: String
    /// Giỗ within 7 days — the days label is emphasised.
    let isSoon: Bool
    /// "Có nhắc", or empty when reminders are off.
    let reminderTag: String
}

/// UI state of the list screen ("Sổ giỗ chạp").
struct ILMemorialStateModel: Equatable {
    /// "3 người thân" / "Chưa có ai"; empty until the first load answers.
    var subtitle: String = ""
    var highlight: ILMemorialHighlightModel?
    var rows: [ILMemorialRowModel] = []
    /// `true` only after a load answered with no entries — not while still loading.
    var isEmpty: Bool = false
    /// Transient confirmation ("Đã lưu vào sổ giỗ."); empty hides the banner.
    var bannerText: String = ""

    static let initial = ILMemorialStateModel()
}
