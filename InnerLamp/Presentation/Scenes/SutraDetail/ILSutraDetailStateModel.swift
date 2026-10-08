//
//  ILSutraDetailStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// 1 chip thông tin ở hero (mục đích tụng / "Có audio" / "✓ Đã tải về") — nhãn đã resolve + cờ
/// kiểu nền.
struct ILSutraDetailTagModel: Equatable {
    let title: String
    /// `true` = nền vàng nhạt (`feat-glow`, chip "Có audio"); `false` = chỉ có viền.
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
    /// Tên nguyên ngữ in nghiêng dưới tiêu đề: "Dhammapada · Pāli".
    var originalName: String = ""
    /// Dòng meta dưới tên nguyên ngữ: "26 phẩm · 423 kệ · Thầy Minh Đạo tụng · 2 giờ 10 phút"
    /// (hoặc "… · Chỉ có văn bản · …" khi bộ kinh không có audio).
    var metaText: String = ""
    var tags: [ILSutraDetailTagModel] = []

    /// `false` ẩn cả thẻ tiến trình — chỉ Kinh Pháp Cú có tiến trình mẫu.
    var hasProgress: Bool = false
    /// Dòng "Bạn đang ở Phẩm Song Yếu · kệ 1" trong thẻ tiến trình.
    var progressTitle: String = ""
    /// "34%" (đã format từ `progressValue`).
    var progressPercentText: String = ""
    /// 0...1 — đưa cho `ILLinearProgressBarView`.
    var progressValue: Double = 0

    var descriptionText: String = ""
    /// "Dịch / hiệu đính: HT Thích Minh Châu".
    var translatorText: String = ""
    var tocTitle: String = ""
    /// "26 phẩm" / "2 phần" (đã format theo `ILSutraDetailStructure`).
    var tocCountText: String = ""
    var chapters: [ILSutraDetailChapterModel] = []

    var downloadButtonTitle: String = ""
    /// "Tụng theo" khi có audio, "Đọc kinh" khi chỉ có văn bản.
    var chantButtonTitle: String = ""
    /// `false` ẩn nút phát tròn ở thanh CTA đáy.
    var hasAudio: Bool = false

    static let initial = ILSutraDetailStateModel()
}
