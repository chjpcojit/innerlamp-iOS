//
//  ILNotificationsStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 dòng thông báo đã sẵn sàng hiển thị (thời gian đã format, không còn Date).
struct ILNotificationItemModel: Equatable {
    let id: String
    let kind: ILNotificationKind
    let title: String
    let body: String
    /// Thời gian tương đối đã format ("vừa xong", "2 giờ", "hôm qua", "3 ngày"...).
    let relativeTime: String
    let isRead: Bool
}

/// Thẻ "Sắp diễn ra" đầu màn đã sẵn sàng hiển thị.
struct ILNotificationsHeroModel: Equatable {
    let eyebrow: String
    let title: String
}

/// Trạng thái UI của màn Thông báo — do `ILNotificationsViewModel` sở hữu, `ViewController` chỉ
/// đọc để render. Không import UIKit, không có logic nghiệp vụ.
struct ILNotificationsStateModel: Equatable {
    /// nil = đã bị ẩn (người dùng chọn "Bỏ qua tối nay") hoặc không có thời khóa sắp tới.
    var hero: ILNotificationsHeroModel?
    var items: [ILNotificationItemModel] = []

    static let initial = ILNotificationsStateModel()
}
