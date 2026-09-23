//
//  ILMalaEntity.swift
//  InnerLamp
//

import Foundation

/// Mốc đặc biệt khi đếm hạt — Presentation dùng để rung nhẹ / báo chuông.
enum ILMalaMilestone: Equatable {
    /// Chạm mỗi phần tư tràng (hạt 27, 54, 81) — rung nhẹ.
    case quarter
    /// Đủ tràng (hạt 108) — chuông.
    case roundComplete
}

/// Pure business entity cho màn Tràng hạt (niệm Phật) — Domain layer only.
///
/// Chỉ chứa số liệu có ý nghĩa nghiệp vụ (số hạt, mục tiêu mỗi tràng, số tràng đã hoàn thành).
/// KHÔNG chứa field chỉ phục vụ hiển thị (chuỗi `.localized`, nhãn "N tràng", tỉ lệ tiến độ) —
/// những field đó nằm ở `ILMalaStateModel`, do `ILMalaViewModel` tự chuyển đổi. Xem
/// `references/data_layer_boundaries.md`.
struct ILMalaEntity: Equatable {
    /// Số hạt đã niệm trong tràng hiện tại, 0...`goal`.
    var count: Int = 0
    /// Số hạt của một tràng.
    var goal: Int = 108
    /// Số tràng đã niệm đủ.
    var completedRounds: Int = 0

    /// Khoảng cách giữa hai mốc rung — một phần tư tràng.
    var quarterInterval: Int { max(1, goal / 4) }

    static let empty = ILMalaEntity()
}
