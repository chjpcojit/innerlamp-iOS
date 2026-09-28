//
//  ILTempleEntity.swift
//  InnerLamp
//

import Foundation

/// Tông màu icon cho 1 hàng "Thời khóa sắp tới" ở Trang chùa — khớp `tone` (gold/green) trong
/// design handoff (`InnerLamp Prototype.dc.html`, `isTemple`). Domain không import UIKit nên map
/// sang `ILColors.Tone` ở tầng ViewController.
enum ILTempleSessionTone: Equatable {
    case gold
    case green
}

/// Hình glyph icon cho 1 hàng "Thời khóa sắp tới" — khớp `glyph` (book/circle) trong design
/// handoff, map sang `ILRow.Glyph` ở tầng ViewController.
enum ILTempleSessionGlyph: Equatable {
    case book
    case circle
}

/// 1 thời khóa sắp tới trong Trang chùa — nội dung catalog (tiêu đề, thời gian/địa điểm, trạng
/// thái ghi danh, tông màu và hình glyph). Chưa có API thời khóa thật (xem TODO ở
/// `ILTempleUseCaseImpl`).
struct ILTempleSessionEntity: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trailingText: String
    let tone: ILTempleSessionTone
    let glyph: ILTempleSessionGlyph
}

/// Khung giờ mở cửa (phút trong ngày, 0...1439) — khớp `hours`/`holHours` (`[open, close]`) trong
/// design handoff.
struct ILTempleOpeningHoursEntity: Equatable {
    let openMinute: Int
    let closeMinute: Int
}

/// 1 mục "Tổ chức & truyền thừa" (Trụ trì / Tổ khai sơn / Giáo hội) — `value == nil` hiển thị
/// "Đang cập nhật" ở Presentation, không ẩn dòng (khớp design handoff `org`).
struct ILTempleOrgInfoEntity: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String?
}

/// 1 ô "Tiện ích" (Bãi đỗ ô tô / Giữ xe máy / Cơm chay / Kinh sách / Khóa tu) — `value == nil`
/// hoặc bắt đầu bằng "Không" (khớp regex `/^Không/` trong design handoff) coi là không có.
struct ILTempleAmenityEntity: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String?
}

/// 1 mục liên hệ (Hotline / Fanpage / Website / Email) — `value == nil` hiển thị "Đang cập nhật".
/// `rawValue` là chuỗi thô (số điện thoại, domain...) dùng để dựng URL `tel:`/`https:`/`mailto:`
/// khi chạm, tách khỏi `value` (chuỗi hiển thị — cùng nội dung, giữ riêng để rõ ý dùng).
struct ILTempleContactEntity: Equatable, Identifiable {
    let id: String
    let label: String
    let rawValue: String?
}

/// Pure business entity cho màn Trang chùa — Domain layer only. Khớp `TEMPLE_INFO` trong design
/// handoff (`InnerLamp Prototype.dc.html`): định danh & vị trí, Phật học & tổ chức, lịch sử &
/// kiến trúc, tiện ích & hỗ trợ.
///
/// Chỉ chứa dữ liệu có ý nghĩa nghiệp vụ thực sự. KHÔNG chứa field chỉ phục vụ hiển thị (nhãn nút,
/// chuỗi đã format sẵn như "Cách bạn 3,2 km", trạng thái mở/đóng cửa lúc này) — những field đó do
/// `ILTempleViewModel` tự suy ra từ `openingHours`/`latitude`/`longitude` (giờ hiện tại + âm lịch
/// không phải dữ liệu catalog, xem `references/data_layer_boundaries.md`).
struct ILTempleEntity: Equatable, Identifiable {
    let id: String

    // MARK: Định danh & vị trí
    let name: String
    /// Tên dân gian khác — rỗng nếu không có (khớp `aliases: []`).
    let aliases: [String]
    let latitude: Double
    let longitude: Double
    let street: String
    let ward: String
    let district: String
    let province: String
    let region: String
    let subRegion: String

    // MARK: Phật học & tổ chức
    let sect: String
    let orgInfo: [ILTempleOrgInfoEntity]

    // MARK: Lịch sử & kiến trúc
    let era: String
    /// Cấp di tích — `nil` = "Chưa xếp hạng" (khớp `rank || 'Chưa xếp hạng'`).
    let rank: String?
    let archStyle: String
    let materials: String
    let highlights: [String]
    let bio: String

    // MARK: Tiện ích & hỗ trợ
    let regularHours: ILTempleOpeningHoursEntity
    let holidayHours: ILTempleOpeningHoursEntity
    let contacts: [ILTempleContactEntity]
    let amenities: [ILTempleAmenityEntity]
    let visitRules: [String]
    let hasUpcomingSchedule: Bool
    let sessions: [ILTempleSessionEntity]

    /// "09/2026" — lần cập nhật dữ liệu gần nhất (khớp `updated`).
    let updatedLabel: String
}
