//
//  ILSanghaEntity.swift
//  InnerLamp
//

import Foundation

/// Thông báo của chùa tu tập — chỉ dữ liệu nghiệp vụ.
struct ILSanghaAnnouncementEntity: Equatable, Identifiable {
    let id: String
    let postedAt: Date
    let text: String
}

/// Hành động trên 1 khóa tu / buổi lễ của chùa.
enum ILSanghaEventAction: Equatable {
    /// "Nhắc tôi" — nhắc lịch (buổi định kỳ).
    case remind
    /// "Giữ chỗ" — giữ chỗ khóa tu.
    case reserve
    /// Không có hành động (hàng chỉ để mở chi tiết).
    case none
}

/// 1 buổi lễ / khóa tu sắp diễn ra.
struct ILSanghaEventEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let title: String
    /// Dòng phụ đã resolve (giờ, địa điểm, số chỗ còn…).
    let detail: String
    let action: ILSanghaEventAction
}

/// 1 pháp thoại tại chùa.
struct ILSanghaTalkEntity: Equatable, Identifiable {
    let id: String
    let title: String
    let speaker: String
    let durationMinutes: Int
}

/// 1 buổi tu học trực tuyến (thiền / tụng kinh livestream).
struct ILSanghaOnlineSessionEntity: Equatable, Identifiable {
    let id: String
    /// Lịch lặp (vd. "HẰNG NGÀY · 20:00").
    let schedule: String
    let isDaily: Bool
    let title: String
    let detail: String
}

/// 1 ngôi chùa trong tab Chùa (chùa tu tập hoặc chùa gợi ý) — dữ liệu mẫu, chưa có API.
struct ILSanghaTempleEntity: Equatable, Identifiable {
    let id: String
    let name: String
    let address: String
    let abbot: String
    /// Giờ mở cửa thô, vd. "06:00 - 18:00".
    let operatingHours: String
    /// Khoảng cách tới người dùng (km) — chỉ dùng cho danh sách "Chùa gần bạn".
    let distanceKm: Double
    /// Ảnh bìa — chuỗi URL đúng như server trả; `nil` với chùa mẫu hoặc chùa không có ảnh.
    var imageURL: String? = nil
}

/// Chùa người dùng đang tu tập cùng nội dung của chùa đó.
struct ILSanghaMyTempleEntity: Equatable {
    let temple: ILSanghaTempleEntity
    let announcements: [ILSanghaAnnouncementEntity]
    let events: [ILSanghaEventEntity]
    let talks: [ILSanghaTalkEntity]
    /// Số Phật tử chọn chùa này làm chùa tu tập (chỉ số, không lộ danh tính).
    let practitionerCount: Int
    /// Số người sẽ về dự khóa tu tới.
    let upcomingRetreatAttendeeCount: Int
}

/// Nội dung tab Chùa khi người dùng chưa chọn chùa tu tập.
struct ILSanghaChooserEntity: Equatable {
    let nearbyTemples: [ILSanghaTempleEntity]
    let onlineSessions: [ILSanghaOnlineSessionEntity]
    let retreats: [ILSanghaEventEntity]
}
