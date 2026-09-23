//
//  ILHomeEntity.swift
//  InnerLamp
//

import Foundation

/// Tông màu icon cho 1 hàng "Thời khóa gợi ý" — khớp `tone` (gold/green/rose/ink) trong
/// design handoff (`InnerLamp Prototype.dc.html`, `isHome`). Domain không import UIKit nên
/// map sang `ILColors.Tone` ở tầng ViewController.
enum ILHomeSessionTone: Equatable {
    case gold
    case green
    case rose
    case ink
}

/// Hình glyph icon cho 1 hàng "Thời khóa gợi ý" — khớp `glyph` (leaf/book/circle/dot) trong
/// design handoff, map sang `ILRow.Glyph` ở tầng ViewController.
enum ILHomeSessionGlyph: Equatable {
    case leaf
    case book
    case circle
    case dot
}

/// 1 mục trong danh sách "Thời khóa gợi ý" — dữ liệu nội dung (catalog), không phải UI state.
struct ILHomeSuggestedSessionEntity: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trailingText: String
    let tone: ILHomeSessionTone
    let glyph: ILHomeSessionGlyph
}

/// Câu kinh/lời dạy trích trong thẻ âm lịch lớn Trang chủ — nhiều dòng + nguồn trích dẫn,
/// khớp `dcVerse`/`dcSource` trong design handoff (`InnerLamp Prototype.dc.html`, `isHome`).
struct ILHomeQuoteEntity: Equatable {
    var lines: [String] = []
    var source: String = ""
}

/// 1 ngày trong dải lịch tuần Trang chủ — ngày dương + số ngày âm tương ứng, tính bằng
/// `ILLunarCalendar` (không phải nội dung tĩnh).
struct ILHomeWeekDayEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let solarDay: Int
    let lunarDay: Int
    let isToday: Bool
}

/// Ngày âm lịch hôm nay hiển thị ở thẻ âm lịch lớn Trang chủ (ngày/tháng/năm âm tính bằng
/// `ILLunarCalendar`, không phải nội dung tĩnh).
struct ILHomeLunarDateEntity: Equatable {
    var solarLabel: String = ""
    var lunarDay: Int = 1
    var lunarMonthLabel: String = ""
    var lunarYearLabel: String = ""
    var verse: ILHomeQuoteEntity = ILHomeQuoteEntity()
}

/// Tông màu 1 sự kiện trong carousel "Sự kiện Phật giáo" — khớp `e.c`/tone trong design handoff.
enum ILHomeEventTone: Equatable {
    case gold
    case green
    case rose
}

/// 1 sự kiện Phật giáo trong tháng — nội dung nghiệp vụ (chưa có API sự kiện chùa thật, xem
/// TODO ở `ILHomeUseCaseImpl`).
struct ILHomeEventItemEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let title: String
    let lunarLabel: String
    let tone: ILHomeEventTone
}

/// 1 trang (tháng) trong carousel "Sự kiện Phật giáo".
struct ILHomeEventMonthEntity: Equatable, Identifiable {
    let id: String
    let monthLabel: String
    let events: [ILHomeEventItemEntity]
}

/// Pure business entity cho màn Trang chủ — Domain layer only.
///
/// Chỉ chứa dữ liệu có ý nghĩa nghiệp vụ thực sự (tên hiển thị, lịch tuần/âm lịch, câu kinh
/// trong ngày, sự kiện Phật giáo, số liệu thời khóa/chuỗi ngày/tràng hạt, danh mục thời khóa gợi
/// ý). KHÔNG chứa field chỉ phục vụ hiển thị (`*Error`, chuỗi `.localized`, format hiển thị) —
/// những field đó nằm ở `ILHomeStateModel` (`Presentation/Scenes/Home/ILHomeStateModel.swift`),
/// do `ILHomeViewModel` tự chuyển đổi qua `applyEntity(_:)`. Xem
/// `references/data_layer_boundaries.md`.
struct ILHomeEntity: Equatable {
    /// Tên hiển thị thô lấy từ phiên đăng ký (có thể rỗng nếu chưa có) — `ILHomeViewModel` mới
    /// là nơi áp fallback "khách" và format câu chào.
    var displayName: String = ""

    var weekDays: [ILHomeWeekDayEntity] = []
    var lunarDate: ILHomeLunarDateEntity = ILHomeLunarDateEntity()
    var eventMonths: [ILHomeEventMonthEntity] = []

    var sessionMinutesDone: Int = 0
    var sessionMinutesGoal: Int = 1

    var streakDays: Int = 0
    /// 7 giá trị 0...1 — độ đậm mỗi cột tuần, ngày cuối cùng là hôm nay.
    var streakWeekProgress: [Double] = []

    var malaCount: Int = 0
    var malaGoal: Int = 108
    var malaMantraText: String = ""

    var suggestedSessions: [ILHomeSuggestedSessionEntity] = []

    static let empty = ILHomeEntity()
}
