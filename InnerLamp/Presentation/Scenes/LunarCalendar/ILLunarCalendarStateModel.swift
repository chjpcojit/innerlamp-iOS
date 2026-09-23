//
//  ILLunarCalendarStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 ô ngày trong lưới tháng — text đã format sẵn, ViewController chỉ đọc để vẽ.
struct ILLunarCalendarDayModel: Equatable, Identifiable {
    let id: String
    /// Số ngày dương ("1"..."31").
    let solarText: String
    /// "Mùng 1" / "Rằm" / số ngày âm.
    let lunarText: String
    let isToday: Bool
    let isSelected: Bool
    let isFastDay: Bool
}

/// 1 trang (tháng) của carousel.
struct ILLunarCalendarMonthModel: Equatable, Identifiable {
    let id: String
    /// Số ô trống đầu tháng khi tuần bắt đầu từ Chủ nhật.
    let leadingBlankDays: Int
    let days: [ILLunarCalendarDayModel]
}

/// 1 hàng "sắp tới" dưới thẻ ngày — `category` để ViewController map sang tone/glyph của `ILRow`.
struct ILLunarCalendarUpcomingModel: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let category: ILLunarCalendarDayCategory
}

/// UI state cho màn Lịch âm — Presentation layer, owned and mutated exclusively by
/// `ILLunarCalendarViewModel`. No UIKit import, no business logic.
struct ILLunarCalendarStateModel: Equatable {
    var headerTitle: String = ""
    var headerSubtitle: String = ""
    var pagerHintText: String = ""
    var weekdayLabels: [String] = []

    var months: [ILLunarCalendarMonthModel] = []
    var currentPage: Int = 0

    var heroEyebrowText: String = ""
    var heroTitle: String = ""
    var heroBody: String = ""
    var heroCategory: ILLunarCalendarDayCategory = .ordinary

    var upcoming: [ILLunarCalendarUpcomingModel] = []

    static let initial = ILLunarCalendarStateModel()
}
