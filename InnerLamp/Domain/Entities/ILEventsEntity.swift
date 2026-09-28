//
//  ILEventsEntity.swift
//  InnerLamp
//

import Foundation

/// Hạng mục màu của một sự kiện — chỉ là category nghiệp vụ (tụng kinh / pháp thoại / ...),
/// chưa phải màu UI. Việc map sang `ILColors.Tone` nằm ở tầng view.
enum ILEventsTone: Equatable {
    case gold
    case green
    case rose
    case ink
}

/// Trạng thái ghi danh của một sự kiện / khóa học.
enum ILEventsStatus: Equatable {
    /// Đang mở ghi danh.
    case open
    /// Sắp đủ chỗ — còn đúng `seatsLeft` chỗ.
    case closing(seatsLeft: Int)
    /// Chưa mở ghi danh.
    case upcoming
    /// Đã ghi danh.
    case registered
}

/// 1 sự kiện / khóa học trong danh sách (chỉ dữ liệu nghiệp vụ, không có chuỗi hiển thị đã format).
struct ILEventsEventEntity: Equatable {
    let id: String
    let name: String
    let subtitle: String
    /// Số ngày (hoặc số tuần đối với khóa học) hiển thị trong ô ngày.
    let day: String
    /// Nhãn đơn vị thời gian (vd. "TH9", "TUẦN").
    let monthLabel: String
    let tone: ILEventsTone
    let status: ILEventsStatus
}

/// Sự kiện nổi bật hiển thị ở thẻ hero tối đầu màn.
struct ILEventsFeaturedEntity: Equatable {
    let id: String
    let day: String
    let monthLabel: String
    let title: String
    let meta: String
    let seatsLeft: Int
}

struct ILEventsEntity: Equatable {
    var featured: ILEventsFeaturedEntity?
    var upcoming: [ILEventsEventEntity] = []
    var courses: [ILEventsEventEntity] = []
    var registered: [ILEventsEventEntity] = []

    static let empty = ILEventsEntity()
}
