//
//  ILTalkStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

/// 1 mốc trong "Các phần" — bản sao presentation của `ILTalkChapterEntity`, kèm timestamp đã
/// format ("00:00", "11:20") và cờ `isCurrent`.
struct ILTalkChapterModel: Equatable, Identifiable {
    let id: String
    let timestampText: String
    let title: String
    let isCurrent: Bool
}

/// UI state cho màn Pháp thoại — Presentation layer, do `ILTalkViewModel` sở hữu và cập nhật
/// độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để render. Các chuỗi
/// đã format ("12:48", "-33:12", "2.4k", dòng meta) nằm ở đây, không nằm trên `ILTalkEntity`
/// (xem `references/data_layer_boundaries.md`).
struct ILTalkStateModel: Equatable {
    var headerTitle: String = ""

    var eyebrow: String = ""
    var title: String = ""
    var narratorInitial: String = ""
    /// "Thầy Minh Đạo · 46 phút · 2.4k lượt nghe".
    var metaText: String = ""

    var descriptionText: String = ""

    /// Nhãn vị trí phát dưới thanh tiến trình.
    var elapsedText: String = ""
    var remainingText: String = ""
    /// Tiến trình phát (0...1).
    var playbackProgress: Double = 0
    /// Đang phát / tạm dừng (đổi glyph nút play/pause).
    var isPlaying: Bool = false

    /// Nhãn nút tua ("15s", "30s").
    var rewindTitle: String = ""
    var forwardTitle: String = ""

    var sectionsTitle: String = ""
    var sectionsEmptyTitle: String = ""
    var sectionsEmptySubtitle: String = ""
    var chapters: [ILTalkChapterModel] = []

    var meditateTitle: String = ""
    var meditateSubtitle: String = ""

    static let initial = ILTalkStateModel()
}
