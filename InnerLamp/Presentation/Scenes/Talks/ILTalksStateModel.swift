//
//  ILTalksStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chip lọc ("Tất cả · 8", "Nghe · 5"...).
struct ILTalksFilterModel: Equatable, Identifiable {
    let id: String
    let label: String
    let value: ILTalkFilter
    let isSelected: Bool
}

/// 1 thẻ bài pháp thoại trong danh sách — bản presentation của `ILTalkListItemEntity`.
struct ILTalksItemModel: Equatable, Identifiable {
    let id: String
    let mediaType: ILTalkMediaType
    /// "MÙA VU LAN" / "VIDEO" / "BẢN GHI" / "BÀI GIẢNG".
    let eyebrow: String
    let title: String
    /// "Thầy Minh Đạo · 46 phút" / "… · 8 phút đọc" / "… · Video".
    let metaText: String
    /// Tiến độ nghe dở (0...1); 0 → ẩn thanh tiến độ.
    let progress: Double
    /// "Đang nghe dở · 28%".
    let progressText: String
}

/// UI state cho màn "Pháp thoại" (danh sách) — do `ILTalksViewModel` sở hữu. Không UIKit.
struct ILTalksStateModel: Equatable {
    var headerTitle: String = ""
    /// "8 bài giảng".
    var subtitle: String = ""
    var filters: [ILTalksFilterModel] = []
    var items: [ILTalksItemModel] = []
    var emptyTitle: String = ""
    var emptyMessage: String = ""

    static let initial = ILTalksStateModel()
}
