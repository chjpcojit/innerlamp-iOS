//
//  ILSutraDetailEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// Một phẩm (chương) trong bộ kinh — khớp mục "Mục lục" của màn `detail` trong design handoff
/// (`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, `isDetail`).
struct ILSutraDetailChapterEntity: Equatable, Identifiable {
    let id: String
    /// Số La Mã của phẩm ("I", "II", ...) — dữ liệu biên tập, không suy ra từ vị trí.
    let number: String
    let title: String
    /// Kệ đầu tiên và cuối cùng của phẩm (dùng để format "Kệ 1 – 20").
    let verseStart: Int
    let verseEnd: Int
    /// Thời lượng tụng phẩm (phút) — format "N phút" thuộc tầng presentation.
    let durationMinutes: Int
}

/// Nhãn thông tin hiển thị dạng chip ở hero của bộ kinh — dữ liệu nghiệp vụ (bộ kinh có được
/// tụng hằng ngày / có bản phiên âm hay không); nhãn chữ và kiểu nền (vàng đậm / viền) là UI state.
enum ILSutraDetailTag: Equatable {
    /// "Tụng hằng ngày" — chip nền vàng đậm.
    case daily
    /// "Có phiên âm" — chip viền.
    case phonetic
}

/// Một bộ kinh đầy đủ để hiển thị ở màn chi tiết bài kinh — khớp `isDetail` trong design handoff.
struct ILSutraDetailSutraEntity: Equatable, Identifiable {
    let id: String
    /// Eyebrow ở hero, ví dụ "KINH VĂN · SONG NGỮ".
    let kicker: String
    let title: String
    /// Người tụng mẫu (giọng đọc audio), ví dụ "Thầy Minh Đạo".
    let narrator: String
    /// Số phẩm của bộ kinh (vd. 26) — dùng cho dòng meta và đếm "N phẩm" ở Mục lục.
    let numberOfChapters: Int
    /// Số kệ của bộ kinh (vd. 423) — dùng cho dòng meta.
    let numberOfVerses: Int
    /// Tổng thời lượng tụng (phút) — format "2 giờ 10 phút" thuộc tầng presentation.
    let durationMinutes: Int
    let description: String
    let tags: [ILSutraDetailTag]
    let chapters: [ILSutraDetailChapterEntity]
}

/// Pure business entity cho màn Chi tiết bài kinh — Domain layer only.
///
/// Chỉ chứa catalog các bộ kinh, bộ kinh đang mở (`currentSutraID`), phẩm đang tụng
/// (`currentChapterID`) và tiến trình đọc (`readingProgress`). Mọi chuỗi đã format ("26 phẩm ·
/// 423 kệ · ...", "Kệ 1 – 20 · đang tụng", "34%") là UI state nên nằm ở `ILSutraDetailStateModel`
/// — xem `references/data_layer_boundaries.md`.
struct ILSutraDetailEntity: Equatable {
    var sutras: [ILSutraDetailSutraEntity] = []
    var currentSutraID: String = ""
    /// Phẩm đang tụng (được tô sáng trong Mục lục).
    var currentChapterID: String = ""
    /// Tiến trình đọc trong toàn bộ bộ kinh (0...1).
    var readingProgress: Double = 0

    static let empty = ILSutraDetailEntity()
}
