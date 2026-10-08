//
//  ILTempleStateModel.swift
//  InnerLamp
//

import Foundation

/// Icon tone of an upcoming-session row — `ViewController` maps it to `ILColors.Tone` (the
/// ViewModel cannot import UIKit).
enum ILTempleSessionTone: Equatable {
    case gold
    case green
}

/// Icon glyph of an upcoming-session row — `ViewController` maps it to `ILRow.Glyph`.
enum ILTempleSessionGlyph: Equatable {
    case book
    case circle
}

/// 1 thời khóa sắp tới trong Trang chùa. `ViewController` map `tone`/`glyph` sang
/// `ILColors.Tone` / `ILRow.Glyph` (giống cách `ILHomeSuggestedSessionModel`).
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
///
/// Only data from the server profile (`GET /v1/temples/{id}`) is filled in. A field the API does
/// not send stays empty (or `hasValue == false`); the section is still shown and the
/// `ViewController` renders the "Đang cập nhật" placeholder in it.
struct ILTempleStateModel: Equatable {

    // MARK: - Header + hero
    /// Tiêu đề header — chỉ hiện khi đã cuộn qua hero (`ViewController` quyết định lúc hiện).
    var headerTitle: String = ""
    var rankChip: String = ""
    var sectChip: String = ""
    var name: String = ""
    var hasAlias: Bool = false
    /// "Còn gọi: Linh Mụ Tự"
    var aliasLine: String = ""
    /// "Phường Kim Long, TP. Huế"
    var placeLine: String = ""
    /// Raw server `image_url` for the hero backdrop — `nil` when the temple has no photo (the
    /// gradient hero shows alone).
    var heroImageURL: String?

    // MARK: - 3 nút
    var followButtonTitle: String = ""
    var directionsButtonTitle: String = ""
    var offerButtonTitle: String = ""

    // MARK: - Thẻ trạng thái
    var isOpen: Bool = false
    var openStatusText: String = ""
    /// "đóng lúc 18:00" / "mở lại 6:00" — empty when the hours are unknown.
    var openNoteText: String = ""
    /// "Cách bạn 3,2 km" — empty until the user's real location is available.
    var distanceText: String = ""
    var hourRows: [ILTempleHourRowModel] = []

    // MARK: - Lưới 4 ô
    var facts: [ILTempleFactModel] = []

    // MARK: - Giới thiệu
    /// Empty when the API has no biography (placeholder shown).
    var descriptionText: String = ""
    var isBiographyExpanded: Bool = false
    var biographyToggleTitle: String = ""

    // MARK: - Tổ chức & truyền thừa
    var orgInfo: [ILTempleOrgInfoModel] = []

    // MARK: - Kiến trúc & di sản
    /// `architecture_heritage` paragraph — empty when unknown (placeholder shown).
    var architectureText: String = ""
    var highlights: [String] = []

    // MARK: - Tiện ích
    var amenities: [ILTempleAmenityModel] = []

    // MARK: - Lưu ý khi viếng thăm
    /// Empty when unknown (placeholder shown).
    var visitRules: [ILTempleRuleModel] = []

    // MARK: - Sự kiện & khóa học
    var hasUpcomingSchedule: Bool = false
    var sessions: [ILTempleSessionModel] = []

    // MARK: - Vị trí & liên hệ
    /// "Đồi Hà Khê, Phường Kim Long, TP. Huế, Tỉnh Thừa Thiên Huế"
    var addressLine: String = ""
    /// "Miền Trung"
    var regionLine: String = ""
    /// "16.4529° B, 107.5458° Đ"
    var coordinateText: String = ""
    var contacts: [ILTempleContactModel] = []

    // MARK: - Chân trang
    /// "Cập nhật 09/2026" — empty when unknown (that part is hidden).
    var updatedText: String = ""

    static let initial = ILTempleStateModel()
}

/// 1 hàng "Lưu ý khi viếng thăm" đã đánh số ("01", "02"...).
struct ILTempleRuleModel: Equatable, Identifiable {
    let id: String
    let number: String
    let text: String
}
