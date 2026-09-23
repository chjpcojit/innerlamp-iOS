//
//  ILHomeStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 hàng trong danh sách "Thời khóa gợi ý" — bản sao presentation của `ILHomeSuggestedSessionEntity`
/// (không thêm field UI nào khác hiện tại, nhưng tách riêng để `ViewController` không phụ thuộc
/// thẳng vào type Domain).
struct ILHomeSuggestedSessionModel: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trailingText: String
    let tone: ILHomeSessionTone
    let glyph: ILHomeSessionGlyph
}

/// 1 ngày trong dải lịch tuần Trang chủ — bản sao presentation của `ILHomeWeekDayEntity`, kèm
/// nhãn thứ trong tuần đã format sẵn cho `ViewController`.
struct ILHomeWeekDayModel: Equatable, Identifiable {
    let id: String
    let weekdayShort: String
    let solarDay: Int
    let lunarDay: Int
    let isToday: Bool
}

/// Thẻ âm lịch lớn Trang chủ — bản sao presentation của `ILHomeLunarDateEntity` cộng nhãn UI
/// tĩnh (`eyebrowText`).
struct ILHomeLunarHeroModel: Equatable {
    var eyebrowText: String = ""
    var solarLabel: String = ""
    var lunarDay: Int = 1
    var lunarMonthLabel: String = ""
    var lunarYearLabel: String = ""
    var verseLines: [String] = []
    var verseSource: String = ""
}

/// 1 sự kiện trong carousel "Sự kiện Phật giáo" — bản sao presentation của
/// `ILHomeEventItemEntity`, kèm ngày/thứ đã format sẵn.
struct ILHomeEventItemModel: Equatable, Identifiable {
    let id: String
    let dayNumber: String
    let weekdayLabel: String
    let title: String
    let lunarLabel: String
    let tone: ILHomeEventTone
}

/// 1 trang (tháng) trong carousel "Sự kiện Phật giáo".
struct ILHomeEventMonthModel: Equatable, Identifiable {
    let id: String
    let monthLabel: String
    let events: [ILHomeEventItemModel]
}

/// UI state cho màn Trang chủ — Presentation layer, do `ILHomeViewModel` sở hữu và cập nhật độc
/// quyền thông qua `applyEntity(_:)`. Không UIKit, không business logic — `ViewController` chỉ
/// đọc để hiển thị. Đây là nơi chứa các chuỗi `.localized` tĩnh (nhãn UI) và giá trị đã format để
/// hiển thị, khác với dữ liệu nghiệp vụ thô nằm trên `ILHomeEntity`
/// (xem `references/data_layer_boundaries.md`).
struct ILHomeStateModel: Equatable {
    var greetingText: String = ""
    var avatarInitial: String = ""
    var dateText: String = ""

    var weekLabelText: String = ""
    var weekDays: [ILHomeWeekDayModel] = []
    var weekCalendarLinkText: String = ""

    var lunarHero: ILHomeLunarHeroModel = ILHomeLunarHeroModel()

    var eventsTitle: String = ""
    var eventsViewAllText: String = ""
    var eventMonths: [ILHomeEventMonthModel] = []

    var sessionMinutesDone: Int = 0
    var sessionMinutesGoal: Int = 1
    var sessionProgress: Double {
        guard sessionMinutesGoal > 0 else { return 0 }
        return min(1, max(0, Double(sessionMinutesDone) / Double(sessionMinutesGoal)))
    }

    var streakDays: Int = 0
    var streakWeekProgress: [Double] = []

    var malaCount: Int = 0
    var malaGoal: Int = 108
    var malaProgress: Double {
        guard malaGoal > 0 else { return 0 }
        return min(1, max(0, Double(malaCount) / Double(malaGoal)))
    }
    var malaMantraText: String = ""
    var malaHelperText: String = ""

    var suggestedSessions: [ILHomeSuggestedSessionModel] = []

    static let initial = ILHomeStateModel()
}
