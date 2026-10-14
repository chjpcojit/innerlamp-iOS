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

/// Loại thực hành của 1 hàng "Thời khóa gợi ý" — quyết định màn đích khi chạm (khớp `on-tap` trong
/// design handoff: `goSetup` / `goReader` / `goOffer`).
enum ILHomeSessionKind: Equatable {
    /// Thiền — mở màn Chuẩn bị thiền (`setup`).
    case meditation
    /// Tụng kinh — màn Đọc kinh (`reader`).
    case sutra
    /// Cúng dường đèn — màn Cúng dường (`offer`).
    case offering
}

/// 1 mục trong danh sách "Thời khóa gợi ý" — dữ liệu nội dung (catalog), không phải UI state.
struct ILHomeSuggestedSessionEntity: Equatable, Identifiable {
    let id: String
    let kind: ILHomeSessionKind
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

extension ILHomeQuoteEntity {
    /// Display form of a catalog quote, shared by the Home hero card and the Lunar Day Detail screen.
    /// Source reads "— Kinh Pháp Cú (Dhammapada), câu 5".
    init(quote: ILSutraQuoteEntity) {
        self.init(
            // The catalog stores each verse as one flat string — restore its 4 poetic lines.
            lines: ILSutraVerseLineSplitter.lines(from: quote.content),
            source: String(format: "home.lunar.verse.sourceFormat".localized, quote.sutraName, quote.verseNumber)
        )
    }
}

/// 1 ngày trong dải lịch tuần Trang chủ — ngày dương + số ngày âm tương ứng, tính bằng
/// `ILLunarCalendar` (không phải nội dung tĩnh). `lunarMonth` dùng để hiển thị "1/9" cho Mùng 1,
/// `isHoangDao` để chấm xanh (Hoàng đạo) hay đỏ (Hắc đạo); Rằm/Mùng Một luôn chấm vàng.
struct ILHomeWeekDayEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let solarDay: Int
    let lunarDay: Int
    let lunarMonth: Int
    let isHoangDao: Bool
    let isToday: Bool
}

/// 1 trang (tuần) trong dải lịch tuần Trang chủ — 5 tuần (2 trước, hiện tại, 2 sau), `label` là
/// khoảng tháng ("Tháng 9 – Tháng 10, 2026").
struct ILHomeWeekPageEntity: Equatable, Identifiable {
    let id: String
    let label: String
    let days: [ILHomeWeekDayEntity]
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

/// 1 sự kiện Phật giáo trong tháng — nội dung nghiệp vụ từ `GET /v1/calendar/events`
/// (xem `ILHomeUseCaseImpl.loadBuddhistEventMonths`).
struct ILHomeEventItemEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let title: String
    let lunarLabel: String
    let tone: ILHomeEventTone
    /// Mã sự kiện trên server — mở màn Chi tiết ngày lễ cùng với `date`.
    var eventCode: String = ""
}

/// 1 trang (tháng) trong carousel "Sự kiện Phật giáo".
struct ILHomeEventMonthEntity: Equatable, Identifiable {
    let id: String
    let monthLabel: String
    let events: [ILHomeEventItemEntity]
}

/// 1 ảnh trong khối "Ảnh chùa đẹp" ở Trang chủ — mapped from the server's featured gallery photos
/// (`GET /v1/gallery/top`, `ILPhotosPhotoEntity`). Home only needs the identity and the thumbnail;
/// title/place belong to the Photos screen.
struct ILHomePhotoEntity: Equatable, Identifiable {
    let id: String
    /// Raw server thumbnail URL; `nil` shows the placeholder.
    var thumbnailURL: String? = nil
}

/// 1 chùa trong carousel "Chùa Việt Nam" — mapped from the server's featured temples
/// (`GET /v1/temples/top`, `ILTempleSummaryEntity`). Raw business data only: the region badge,
/// short place line and "rank · founded" note are formatted by `ILHomeViewModel`.
struct ILHomeTempleEntity: Equatable, Identifiable {
    let id: String
    let name: String
    /// Full street address from the server, e.g. "Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình".
    let address: String
    let region: ILTempleRegion
    let heritageRank: ILTempleHeritageRank
    /// Founding year; `<= 0` when unknown.
    let establishedYear: Int
    /// Raw server thumbnail URL; `nil` when the temple has no photo.
    var thumbnailURL: String? = nil
}

/// 1 bài viết trong danh sách "Bài viết Phật pháp hay" — nội dung catalog. `readMinutes` là dữ
/// liệu (số phút đọc); chuỗi "… phút đọc" do `ILHomeViewModel` format khi map sang StateModel.
struct ILHomeArticleEntity: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    let readMinutes: Int
    /// Raw server thumbnail URL (`thumbnail_url`, falling back to `image_url`); `nil` when the
    /// article has no image.
    var thumbnailURL: String? = nil
}

/// 1 vị Phật / Bồ Tát trong carousel "Thư viện Phật & Bồ Tát" ở Trang chủ — bản tóm tắt catalog
/// (danh xưng, loại, hiệu tôn, đức hạnh, ngày vía chính). Dữ liệu đầy đủ nằm trên `ILDeityEntity`
/// (màn chi tiết `Deity`). Trang chủ map từ `GET /v1/deities/top` (`ILHomeUseCase.loadTopDeities()`),
/// Thư viện map từ `ILDeityUseCase.getAllDeities()`.
struct ILHomeDeityEntity: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    let name: String
    let honorific: String
    let virtue: String
    /// Ngày vía chính theo âm lịch (ngày đản sinh / "Vía" nếu có, ngược lại là ngày lễ đầu tiên
    /// trong catalog). `nil` khi catalog không có ngày lễ nào.
    let memorialDay: ILDeityMemorialDayEntity?
    /// Raw server thumbnail URL; `nil` (bundled catalog) shows the placeholder.
    var thumbnailURL: String? = nil
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

    /// 5 trang tuần quanh tuần hiện tại (mỗi trang 7 ngày Thứ Hai → Chủ nhật).
    var weekPages: [ILHomeWeekPageEntity] = []
    /// id ngày đang chọn trong dải lịch tuần (mặc định hôm nay) — quyết định ô tô đậm + thẻ âm
    /// lịch lớn.
    var selectedDayID: String = ""
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

    var photos: [ILHomePhotoEntity] = []
    var temples: [ILHomeTempleEntity] = []
    var articles: [ILHomeArticleEntity] = []
    /// Carousel "Thư viện Phật & Bồ Tát" — featured deities from the server
    /// (`ILHomeUseCase.loadTopDeities()`).
    var deities: [ILHomeDeityEntity] = []

    static let empty = ILHomeEntity()
}
