//
//  ILSutraDetailStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// 1 chip thông tin ở hero (Tụng hằng ngày / Có phiên âm) — nhãn đã resolve + cờ kiểu nền.
struct ILSutraDetailTagModel: Equatable {
    let title: String
    /// `true` = nền vàng đậm (chip "Tụng hằng ngày"); `false` = chip viền (chip "Có phiên âm").
    let isFilled: Bool
}

/// 1 hàng trong Mục lục — bản sao presentation của `ILSutraDetailChapterEntity`, kèm các chuỗi
/// đã format ("Kệ 1 – 20 · đang tụng", "9 phút") và cờ `isCurrent`.
struct ILSutraDetailChapterModel: Equatable, Identifiable {
    let id: String
    let number: String
    let title: String
    let subtitle: String
    let durationText: String
    let isCurrent: Bool
}

/// UI state cho màn Chi tiết bài kinh — Presentation layer, do `ILSutraDetailViewModel` sở hữu và
/// cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị.
/// Các chuỗi đã format ("26 phẩm · 423 kệ · ...", "34%", nhãn chip) nằm ở đây, không nằm trên
/// `ILSutraDetailEntity` (xem `references/data_layer_boundaries.md`).
struct ILSutraDetailStateModel: Equatable {
    var kicker: String = ""
    var title: String = ""
    /// Dòng meta dưới tiêu đề: "26 phẩm · 423 kệ · Thầy Minh Đạo tụng · 2 giờ 10 phút".
    var metaText: String = ""
    var tags: [ILSutraDetailTagModel] = []

    /// Dòng "Bạn đang ở Phẩm Song Yếu · kệ 1" trong thẻ tiến trình.
    var progressTitle: String = ""
    /// "34%" (đã format từ `progressValue`).
    var progressPercentText: String = ""
    /// 0...1 — đưa cho `ILLinearProgressBarView`.
    var progressValue: Double = 0

    var descriptionText: String = ""
    var tocTitle: String = ""
    /// "26 phẩm" (đếm phẩm, đã format).
    var tocCountText: String = ""
    var chapters: [ILSutraDetailChapterModel] = []

    var downloadButtonTitle: String = ""
    var chantButtonTitle: String = ""

    static let initial = ILSutraDetailStateModel()
}
