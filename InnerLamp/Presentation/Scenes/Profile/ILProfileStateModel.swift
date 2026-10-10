//
//  ILProfileStateModel.swift
//  InnerLamp
//

import Foundation
import CoreGraphics

/// Dải đầu trang: avatar + tên + dòng phụ, đã sẵn sàng hiển thị.
struct ILProfileHeaderModel: Equatable {
    let initial: String
    let fullName: String
    let subtitle: String
    /// Đoạn trong `subtitle` được nhấn màu (pháp danh); nil khi chưa có pháp danh.
    let subtitleHighlight: String?
}

/// 1 ô số liệu ("168" / "giờ tu tập").
struct ILProfileStatModel: Equatable {
    let value: String
    let caption: String
}

/// Thẻ "Nhật ký 12 tuần qua": chú thích tổng hợp + độ đậm từng ô (đã chuẩn hóa thành alpha).
struct ILProfileHeatmapModel: Equatable {
    let summaryText: String
    let intensities: [CGFloat]
}

/// 1 huy hiệu dấu ấn đã sẵn sàng hiển thị.
struct ILProfileBadgeModel: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let category: ILProfileBadgeCategory
}

/// Trạng thái UI của màn Tôi — do `ILProfileViewModel` sở hữu, `ViewController` chỉ đọc để render.
struct ILProfileStateModel: Equatable {
    var header = ILProfileHeaderModel(initial: "", fullName: "", subtitle: "", subtitleHighlight: nil)
    var stats: [ILProfileStatModel] = []
    var heatmap: ILProfileHeatmapModel?
    var badgesLinkText: String = ""
    var badges: [ILProfileBadgeModel] = []
    var meritSummary: String = ""
    var reminderValue: String = ""
    var communityValue: String = ""
    /// Chân trang: "InnerLamp · Phiên bản 1.4.2" / "Bản dựng 218" (đọc từ bundle).
    var versionText: String = ""
    var buildText: String = ""

    var hasBadges: Bool { !badges.isEmpty }

    static let initial = ILProfileStateModel()
}
