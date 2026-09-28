//
//  ILLunarCalendarEntity.swift
//  InnerLamp
//

import Foundation

/// Loại ngày trong lịch âm theo nghiệp vụ tu tập — chỉ phân loại, không chứa nội dung hiển thị
/// (copy nằm ở `ILLunarCalendarViewModel`).
enum ILLunarCalendarDayCategory: Equatable {
    /// Mùng 1 âm lịch.
    case newMoon
    /// Rằm (15 âm lịch).
    case fullMoon
    /// Ngày trai khác (8, 14, 18, 23, 30 âm lịch) — ăn chay, giữ giới.
    case fastDay
    /// Ngày thường.
    case ordinary
}

/// 1 ngày dương trong tháng kèm ngày âm tương ứng, tính bằng `ILLunarCalendar`.
struct ILLunarCalendarDayEntity: Equatable, Identifiable {
    /// `yyyy-MM-dd` — khóa ổn định để chọn ngày và so sánh với hôm nay.
    let id: String
    let date: Date
    let solarDay: Int
    let lunarDay: Int
    let lunarMonth: Int
    let isLunarLeapMonth: Bool
    let category: ILLunarCalendarDayCategory
    /// `true` = ngày Hoàng đạo (tốt), `false` = Hắc đạo (xấu) — xem `ILLunarCalendar.isHoangDao`.
    let isHoangDao: Bool

    /// Ngày trai gồm mùng 1, rằm và các ngày trai còn lại.
    var isFastDay: Bool { category != .ordinary }
}

/// 1 tháng dương lịch (1 trang của carousel) — danh sách ngày + số ô trống đầu tháng và tháng/
/// năm âm ở giữa tháng (ngày 15 dương) dùng làm phụ đề "Âm lịch ...".
struct ILLunarCalendarMonthEntity: Equatable, Identifiable {
    /// `yyyy-MM`.
    let id: String
    let solarMonth: Int
    let solarYear: Int
    /// Số ô trống trước ngày 1 khi tuần bắt đầu từ Chủ nhật (Chủ nhật = 0).
    let leadingBlankDays: Int
    let days: [ILLunarCalendarDayEntity]
    let midLunarMonth: Int
    let midLunarYear: Int
    let isMidLunarLeapMonth: Bool
}

/// Pure business entity cho màn Lịch âm — Domain layer only.
///
/// Chỉ chứa dữ liệu lịch (các tháng, hôm nay, ngày đang chọn). Nhãn hiển thị, copy và trạng thái
/// trang carousel là UI state nên nằm ở `ILLunarCalendarStateModel` — xem
/// `references/data_layer_boundaries.md`.
struct ILLunarCalendarEntity: Equatable {
    var months: [ILLunarCalendarMonthEntity] = []
    var todayID: String = ""
    var selectedDayID: String = ""

    var selectedDay: ILLunarCalendarDayEntity? {
        day(withID: selectedDayID)
    }

    func day(withID id: String) -> ILLunarCalendarDayEntity? {
        for month in months {
            if let day = month.days.first(where: { $0.id == id }) { return day }
        }
        return nil
    }

    static let empty = ILLunarCalendarEntity()
}
