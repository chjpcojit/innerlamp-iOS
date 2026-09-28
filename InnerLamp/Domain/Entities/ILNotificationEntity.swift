//
//  ILNotificationEntity.swift
//  InnerLamp
//

import Foundation

/// Loại thông báo — quyết định ý nghĩa nghiệp vụ (và ánh xạ màu ở tầng hiển thị, không nằm ở đây).
enum ILNotificationKind: Equatable {
    /// Chuông tỉnh thức / nhắc giờ thực hành.
    case bell
    /// Sự kiện / thời khóa của đạo tràng.
    case sangha
    /// Tương tác từ bạn đồng tu (tùy hỷ, bình luận...).
    case community
    /// Biên nhận cúng dường.
    case offering
}

/// Một thông báo trong danh sách — chỉ dữ liệu nghiệp vụ, không có chuỗi đã format hay trạng thái UI.
struct ILNotificationEntity: Equatable {
    let id: String
    let kind: ILNotificationKind
    let title: String
    let body: String
    /// Thời điểm thông báo xảy ra — tầng hiển thị format thành "vừa xong"/"2 giờ"/"hôm qua"...
    let timestamp: Date
    /// `false` = chưa đọc (hiện chấm vàng ở tầng hiển thị).
    let isRead: Bool
}

/// Thẻ "Sắp diễn ra" đầu màn — thời khóa/phiên thực hành sắp tới kèm CTA.
struct ILNotificationUpcomingEntity: Equatable {
    /// Dòng eyebrow đã resolve (vd. "SẮP DIỄN RA · 30 PHÚT NỮA").
    let eyebrow: String
    /// Tiêu đề thời khóa (vd. "Thời khóa tối cùng đạo tràng").
    let title: String
}
