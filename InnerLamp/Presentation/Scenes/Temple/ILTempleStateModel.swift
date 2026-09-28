//
//  ILTempleStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 thời khóa sắp tới trong Trang chùa — bản sao presentation của `ILTempleSessionEntity`.
/// Giữ nguyên `tone`/`glyph` dạng enum Domain, `ViewController` map sang `ILColors.Tone` /
/// `ILRow.Glyph` (giống cách `ILHomeSuggestedSessionModel`).
struct ILTempleSessionModel: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trailingText: String
    let tone: ILTempleSessionTone
    let glyph: ILTempleSessionGlyph
}

/// 1 hàng giờ mở cửa trong thẻ trạng thái (Ngày thường / Rằm & Mùng Một) — `isToday` hiện nhãn
/// "Hôm nay" trên dòng khung giờ đang áp dụng.
struct ILTempleHourRowModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let isToday: Bool
}

/// 1 ô trong lưới "Niên đại · Cấp di tích · Hệ phái · Vùng miền".
struct ILTempleFactModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
}

/// 1 hàng "Tổ chức & truyền thừa" — `hasValue == false` hiển thị "Đang cập nhật" (nghiêng, mờ).
struct ILTempleOrgInfoModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let hasValue: Bool
}

/// 1 ô "Tiện ích" — `isAvailable` quyết định dấu ✓ (xanh) hay vòng rỗng + nền trong suốt.
struct ILTempleAmenityModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let isAvailable: Bool
}

/// 1 mục liên hệ (Hotline / Fanpage / Website / Email) — `hasValue == false` hiển thị
/// "Đang cập nhật" và không thể chạm.
struct ILTempleContactModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let hasValue: Bool
}

/// UI state cho màn Trang chùa — Presentation layer, do `ILTempleViewModel` sở hữu và cập nhật
/// độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị.
struct ILTempleStateModel: Equatable {

    // MARK: - Header + hero
    /// Tiêu đề header — chỉ hiện khi đã cuộn qua hero (`ViewController` quyết định lúc hiện).
    var headerTitle: String = ""
    var rankChip: String = ""
    var sectChip: String = ""
    var name: String = ""
    var hasAlias: Bool = false
    /// "Diên Hựu tự · Liên Hoa Đài"
    var aliasLine: String = ""
    /// "Quận Bình Thạnh, TP. Hồ Chí Minh"
    var placeLine: String = ""

    // MARK: - 3 nút
    var followButtonTitle: String = ""
    var directionsButtonTitle: String = ""
    var offerButtonTitle: String = ""

    // MARK: - Thẻ trạng thái
    var isOpen: Bool = true
    var openStatusText: String = ""
    /// "đóng lúc 20:00" / "mở lại 5:00"
    var openNoteText: String = ""
    /// "Cách bạn 3,2 km"
    var distanceText: String = ""
    var hourRows: [ILTempleHourRowModel] = []

    // MARK: - Lưới 4 ô
    var facts: [ILTempleFactModel] = []

    // MARK: - Giới thiệu
    var descriptionText: String = ""
    var isBiographyExpanded: Bool = false
    var biographyToggleTitle: String = ""

    // MARK: - Tổ chức & truyền thừa
    var orgInfo: [ILTempleOrgInfoModel] = []

    // MARK: - Kiến trúc & di sản
    var archStyle: String = ""
    var materials: String = ""
    var highlights: [String] = []

    // MARK: - Tiện ích
    var amenities: [ILTempleAmenityModel] = []

    // MARK: - Lưu ý khi viếng thăm
    var visitRules: [ILTempleRuleModel] = []

    // MARK: - Sự kiện & khóa học
    var hasUpcomingSchedule: Bool = false
    var sessions: [ILTempleSessionModel] = []

    // MARK: - Vị trí & liên hệ
    /// "128 Nguyễn Văn Đậu, Phường 5, Quận Bình Thạnh, TP. Hồ Chí Minh"
    var addressLine: String = ""
    /// "Miền Nam · Đông Nam Bộ"
    var regionLine: String = ""
    /// "10.8030° B, 106.6960° Đ"
    var coordinateText: String = ""
    var contacts: [ILTempleContactModel] = []

    // MARK: - Chân trang
    /// "Cập nhật 09/2026"
    var updatedText: String = ""

    static let initial = ILTempleStateModel()
}

/// 1 hàng "Lưu ý khi viếng thăm" đã đánh số ("01", "02"...).
struct ILTempleRuleModel: Equatable, Identifiable {
    let id: String
    let number: String
    let text: String
}
