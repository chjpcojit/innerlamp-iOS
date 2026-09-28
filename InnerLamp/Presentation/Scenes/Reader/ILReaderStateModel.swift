//
//  ILReaderStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state cho màn Tụng kinh — Presentation layer, do `ILReaderViewModel` sở hữu và cập nhật độc
/// quyền thông qua `applyEntity(_:)`. Không UIKit, không business logic — `ViewController` chỉ đọc
/// để hiển thị. Các chuỗi đã format ("Đang phát · Thầy Minh Đạo", "12:04", "1.0×") và nhãn chip
/// nằm ở đây, không nằm trên `ILReaderEntity` (xem `references/data_layer_boundaries.md`).
struct ILReaderStateModel: Equatable {
    /// Tựa đề + phụ đề dải header ("Kinh Pháp Cú" / "Phẩm Song Yếu · kệ 1–2").
    var title: String = ""
    var subtitle: String = ""

    /// Tiến trình đọc trong bộ kinh (0...1) — thanh tiến trình ở đầu màn.
    var readingProgress: Double = 0

    /// Kệ đang hiển thị (Việt) + bản dịch (Anh).
    var verseText: String = ""
    var translationText: String = ""
    /// Kệ kế tiếp (bản xem trước mờ); rỗng nếu không còn kệ sau.
    var nextVerseText: String = ""

    /// Nhãn nút hành động "Aa" ở header và 2 chip dưới bản dịch.
    var fontSizeActionTitle: String = ""
    var shareChipTitle: String = ""
    var downloadChipTitle: String = ""

    /// Dòng "Đang phát · Thầy Minh Đạo" trên thanh phát.
    var nowPlayingText: String = ""
    /// Vị trí phát dạng "12:04".
    var elapsedText: String = ""
    /// Tiến trình phát audio (0...1) — thanh tiến trình trên thanh phát.
    var playbackProgress: Double = 0
    /// Nhãn tốc độ "1.0×".
    var speedText: String = ""
    /// Đang phát (điều khiển icon play/pause).
    var isPlaying: Bool = false

    static let initial = ILReaderStateModel()
}
