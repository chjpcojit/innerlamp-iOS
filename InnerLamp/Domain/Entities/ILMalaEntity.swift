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
/// Chỉ chứa số liệu có ý nghĩa nghiệp vụ (số hạt, mục tiêu mỗi vòng, vòng đang niệm).
/// KHÔNG chứa field chỉ phục vụ hiển thị (chuỗi `.localized`, nhãn "N tràng", tỉ lệ tiến độ) —
/// những field đó nằm ở `ILMalaStateModel`, do `ILMalaViewModel` tự chuyển đổi. Xem
/// `references/data_layer_boundaries.md`.
struct ILMalaEntity: Equatable {
    /// Các mục tiêu (số biến) người dùng được chọn cho một vòng.
    static let goalOptions = [21, 54, 108]

    /// Số hạt đã niệm trong vòng hiện tại, 0...`goal`.
    var count: Int = 0
    /// Số biến của một vòng.
    var goal: Int = 108
    /// Vòng đang niệm, bắt đầu từ 1; tăng khi người dùng chọn "Niệm tiếp vòng mới".
    var round: Int = 1

    /// Đã niệm đủ `goal` biến — vòng chờ người dùng chọn niệm tiếp hoặc kết thúc.
    var isRoundComplete: Bool { count >= goal }

    /// Khoảng cách giữa hai mốc rung — một phần tư tràng.
    var quarterInterval: Int { max(1, goal / 4) }

    static let empty = ILMalaEntity()
}
