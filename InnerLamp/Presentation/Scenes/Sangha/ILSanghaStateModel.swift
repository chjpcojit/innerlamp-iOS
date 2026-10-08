//
//  ILSanghaStateModel.swift
//  InnerLamp
//

import Foundation

struct ILSanghaAnnouncementRowModel: Equatable, Identifiable {
    let id: String
    /// "Hôm nay" / "N ngày trước".
    let timeText: String
    let text: String
}

/// 1 buổi lễ / khóa tu: cột ngày-tháng, tiêu đề, dòng phụ và (tùy chọn) nút pill.
struct ILSanghaEventRowModel: Equatable, Identifiable {
    let id: String
    /// "08".
    let dayNumber: String
    /// "TH10".
    let monthLabel: String
    let title: String
    let subtitle: String
    /// "Nhắc tôi" / "Đã nhắc" / "Giữ chỗ" / "Đã giữ chỗ"; `nil` khi hàng không có nút.
    let actionLabel: String?
    let isActionOn: Bool
    /// `true` với "Nhắc tôi" (pill vàng khi bật), `false` với "Giữ chỗ" (pill đặc khi bật).
    let isGoldAction: Bool
}

struct ILSanghaTalkRowModel: Equatable, Identifiable {
    /// Vị trí trong danh sách — `talkID` có thể trùng giữa các hàng.
    let id: Int
    let talkID: String
    let title: String
    let subtitle: String
}

struct ILSanghaNearbyRowModel: Equatable, Identifiable {
    let id: String
    let name: String
    let subtitle: String
}

struct ILSanghaOnlineRowModel: Equatable, Identifiable {
    let id: String
    let schedule: String
    let isDaily: Bool
    let title: String
    let subtitle: String
}

/// Ngày lễ / ngày trai giới sắp tới: cột ngày-tháng, tiêu đề, phụ đề, gợi ý thực hành và nút nhắc.
struct ILSanghaDayRowModel: Equatable, Identifiable {
    let id: String
    let dayNumber: String
    let monthLabel: String
    let title: String
    let subtitle: String
    let suggestion: String
    /// `true` với lễ có tên (tô màu nhấn số ngày).
    let isFestival: Bool
    let reminderLabel: String
    let isReminderOn: Bool
}

/// Trạng thái "đã chọn chùa tu tập" — thẻ chùa, thông báo, khóa tu & lễ, pháp thoại, cúng dường.
struct ILSanghaMyTempleModel: Equatable {
    let id: String
    let name: String
    let place: String
    /// "Đang mở · đến 18:00" / "Đã đóng · mở 6:00"; rỗng khi không có giờ mở cửa hợp lệ.
    let statusText: String
    let isOpen: Bool
    let abbotText: String
    let announcements: [ILSanghaAnnouncementRowModel]
    let events: [ILSanghaEventRowModel]
    let talks: [ILSanghaTalkRowModel]
    let offerSubtitle: String
    let peersText: String
}

/// Trạng thái "chưa chọn chùa tu tập" — chùa gần bạn, chùa trực tuyến, khóa tu sắp diễn ra.
struct ILSanghaChooserModel: Equatable {
    let locationText: String
    let nearby: [ILSanghaNearbyRowModel]
    let online: [ILSanghaOnlineRowModel]
    let retreats: [ILSanghaEventRowModel]
}

/// Trạng thái UI của tab Chùa — do `ILSanghaViewModel` sở hữu, `ViewController` chỉ đọc để render.
/// `myTemple` có giá trị → đã chọn chùa; `chooser` có giá trị → chưa chọn.
struct ILSanghaStateModel: Equatable {
    var myTemple: ILSanghaMyTempleModel?
    var chooser: ILSanghaChooserModel?
    var days: [ILSanghaDayRowModel] = []

    static let initial = ILSanghaStateModel()
}
