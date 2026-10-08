//
//  ILTalksEntity.swift
//  InnerLamp
//

import Foundation

/// Hình thức của 1 bài pháp thoại — khớp `type` (`audio` / `youtube` / `text`) trong design handoff.
enum ILTalkMediaType: Equatable {
    case audio
    case video
    case text
}

/// Bộ lọc của danh sách pháp thoại — khớp 4 chip Tất cả / Nghe / Xem / Đọc.
enum ILTalkFilter: Equatable, CaseIterable {
    case all
    case media(ILTalkMediaType)

    static let allCases: [ILTalkFilter] = [.all, .media(.audio), .media(.video), .media(.text)]
}

/// 1 dòng trong danh sách pháp thoại — chỉ dữ liệu nghiệp vụ, chuỗi hiển thị là việc của ViewModel.
struct ILTalkListItemEntity: Equatable, Identifiable {
    let id: String
    let mediaType: ILTalkMediaType
    /// Mùa (vd. "Mùa Vu Lan") — `nil` khi bài không thuộc mùa nào.
    let season: String?
    let title: String
    let speaker: String
    /// Thời lượng nghe (phút) — `nil` với video/văn bản.
    let durationMinutes: Int?
    /// Thời gian đọc (phút) — chỉ có với bài văn bản.
    let readMinutes: Int?
    /// Tiến độ nghe dở (0...1); 0 = chưa nghe.
    let listenProgress: Double
}
