//
//  ILEventsStateModel.swift
//  InnerLamp
//

import Foundation

/// Tab đang chọn của màn Sự kiện & khóa học.
enum ILEventsTab: Int, Equatable {
    case upcoming = 0
    case courses
    case registered
}

/// Thẻ hero tối "Sắp diễn ra" đã sẵn sàng hiển thị (nhãn CTA, số chỗ đã format).
struct ILEventsFeaturedModel: Equatable {
    let id: String
    let day: String
    let monthLabel: String
    let eyebrowText: String
    let title: String
    let metaText: String
    let ctaTitle: String
    let seatsText: String
}

/// 1 hàng sự kiện đã sẵn sàng hiển thị (trạng thái đã format, tone giữ nguyên để view map màu).
struct ILEventsListItemModel: Equatable {
    let id: String
    let day: String
    let monthLabel: String
    let title: String
    let subtitle: String
    let statusText: String
    let tone: ILEventsTone
}

/// Trạng thái UI của màn Sự kiện & khóa học — do `ILEventsViewModel` sở hữu, `ViewController` chỉ đọc để render.
struct ILEventsStateModel: Equatable {
    var selectedTab: ILEventsTab = .upcoming
    var featured: ILEventsFeaturedModel?
    var listTitle: String = ""
    var items: [ILEventsListItemModel] = []

    var hasItems: Bool { !items.isEmpty }

    static let initial = ILEventsStateModel()
}
