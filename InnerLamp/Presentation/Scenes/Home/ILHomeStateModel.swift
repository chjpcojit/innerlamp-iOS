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

/// Loại chấm màu dưới 1 ô ngày trong dải lịch tuần — khớp bảng chú thích Hoàng đạo/Hắc đạo/
/// Rằm·Mùng Một trong design handoff.
enum ILHomeWeekDotKind: Equatable {
    /// Rằm (15 âm) / Mùng Một (1 âm) — chấm vàng.
    case newMoonFullMoon
    /// Hoàng đạo — chấm xanh.
    case hoangDao
    /// Hắc đạo — chấm đỏ.
    case hacDao
}

/// 1 ngày trong dải lịch tuần Trang chủ — bản sao presentation của `ILHomeWeekDayEntity`, kèm
/// chuỗi ngày âm và loại chấm đã tính sẵn cho `ViewController`.
struct ILHomeWeekDayModel: Equatable, Identifiable {
    let id: String
    let solarDay: Int
    /// "1/9" cho Mùng 1, ngược lại là số ngày âm.
    let lunarText: String
    let dotKind: ILHomeWeekDotKind
    let isToday: Bool
    let isSelected: Bool
}

/// 1 trang (tuần) trong dải lịch tuần Trang chủ.
struct ILHomeWeekPageModel: Equatable, Identifiable {
    let id: String
    let label: String
    let days: [ILHomeWeekDayModel]
}

/// 1 mục trong bảng chú thích dưới dải lịch tuần (Hoàng đạo / Hắc đạo / Rằm · Mùng Một).
struct ILHomeWeekLegendModel: Equatable {
    let text: String
    let dotKind: ILHomeWeekDotKind
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
    /// Tổng số sự kiện thật của tháng (trước khi bị cắt còn tối đa `maxEventsPerMonthCard`
    /// để hiển thị) — dùng cho badge số đếm, không phụ thuộc vào số dòng đang render.
    let totalEventsCount: Int
    /// Tháng dương lịch hiện tại — carousel dùng để mở đúng thẻ này lần đầu hiển thị, thay vì
    /// luôn mở thẻ đầu tiên (khớp `month.id` dạng `yyyy-MM` do `ILHomeUseCaseImpl` sinh ra).
    let isCurrentMonth: Bool
}

/// 1 ảnh trong khối "Ảnh chùa đẹp" — bản sao presentation của `ILHomePhotoEntity`.
struct ILHomePhotoModel: Equatable, Identifiable {
    let id: String
}

/// 1 chùa trong carousel "Chùa Việt Nam" — bản sao presentation của `ILHomeTempleEntity`.
struct ILHomeTempleModel: Equatable, Identifiable {
    let id: String
    let name: String
    let place: String
    let region: String
    let note: String
}

/// 1 bài viết trong danh sách "Bài viết Phật pháp hay" — bản sao presentation của
/// `ILHomeArticleEntity`, kèm chuỗi "… phút đọc" đã format sẵn.
struct ILHomeArticleModel: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    let readText: String
}

/// 1 vị Phật / Bồ Tát trong carousel "Thư viện Phật & Bồ Tát" — bản presentation của
/// `ILHomeDeityEntity`: badge loại ("Phật" / "Bồ Tát") và dòng ngày vía ("Vía 15/04 âm lịch") đã
/// format sẵn.
struct ILHomeDeityModel: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    let kindLabel: String
    let name: String
    /// Rỗng khi vị này không có ngày vía trong catalog — thẻ ẩn dòng này.
    let memorialText: String
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

    /// Nhãn 7 cột ("Hai"..."CN", CN đỏ) — cố định thứ tự Thứ Hai → Chủ nhật.
    var weekdayLabels: [String] = []
    var weekPages: [ILHomeWeekPageModel] = []
    var weekLegend: [ILHomeWeekLegendModel] = []
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

    var photosTitle: String = ""
    var photosViewAllText: String = ""
    var photos: [ILHomePhotoModel] = []
    var photosMoreText: String = ""
    var photosMoreLabel: String = ""

    var templesTitle: String = ""
    var templesFindText: String = ""
    var temples: [ILHomeTempleModel] = []

    var deitiesTitle: String = ""
    var deitiesViewAllText: String = ""
    var deities: [ILHomeDeityModel] = []

    var bellTitle: String = ""
    var bellSubtitle: String = ""

    var articlesTitle: String = ""
    var articlesViewAllText: String = ""
    var articles: [ILHomeArticleModel] = []

    static let initial = ILHomeStateModel()
}
