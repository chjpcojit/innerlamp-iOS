//
//  ILReaderEntity.swift
//  InnerLamp
//

import Foundation

/// Một kệ kinh song ngữ (Việt + Anh) trong màn Tụng kinh — khớp `isReader` trong design handoff
/// (`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`).
struct ILReaderVerseEntity: Equatable {
    /// Kệ kinh tiếng Việt, có thể chứa `\n` để xuống dòng theo bản kinh.
    let vietnamese: String
    /// Bản dịch tiếng Anh của kệ.
    let english: String
}

/// Một bộ kinh đầy đủ để tụng: tựa đề, phẩm/kệ đang xem, người tụng mẫu (audio) và các kệ.
struct ILReaderSutraEntity: Equatable, Identifiable {
    let id: String
    let title: String
    /// Dòng phụ dưới tựa đề, ví dụ "Phẩm Song Yếu · kệ 1–2".
    let subtitle: String
    /// Tên người tụng mẫu (giọng đọc audio), ví dụ "Thầy Minh Đạo".
    let narrator: String
    /// Tổng thời lượng audio tụng theo (giây) — dùng để tính tiến trình thanh phát.
    let totalDurationSeconds: Int
    let verses: [ILReaderVerseEntity]
}

/// Pure business entity cho màn Tụng kinh — Domain layer only.
///
/// Chỉ chứa dữ liệu nghiệp vụ: catalog các bộ kinh, bộ kinh đang mở (`currentSutraID`), kệ đang
/// đọc (`currentVerseIndex`) và trạng thái phát audio (`isPlaying`, `elapsedSeconds`,
/// `playbackSpeed`, `readingProgress`). Mọi chuỗi đã format ("Đang phát · Thầy Minh Đạo",
/// "12:04", "1.0×") là UI state nên nằm ở `ILReaderStateModel` — xem
/// `references/data_layer_boundaries.md`.
struct ILReaderEntity: Equatable {
    var sutras: [ILReaderSutraEntity] = []
    var currentSutraID: String = ""
    /// Chỉ số kệ đang hiển thị trong `verses` của bộ kinh hiện tại.
    var currentVerseIndex: Int = 0
    /// Tiến trình đọc trong toàn bộ bộ kinh (0...1) — thanh tiến trình ở đầu màn.
    var readingProgress: Double = 0
    /// Vị trí phát audio hiện tại (giây).
    var elapsedSeconds: Int = 0
    /// Tốc độ phát (1.0× mặc định).
    var playbackSpeed: Double = 1.0
    /// Đang phát / tạm dừng — trạng thái in-memory cho tới khi có audio thật.
    var isPlaying: Bool = false

    static let empty = ILReaderEntity()
}
