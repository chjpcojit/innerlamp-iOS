//
//  ILOrdinationPlaceEntity.swift
//  InnerLamp
//

import Foundation

/// Một lựa chọn "Nơi xuất gia" ở màn Đăng ký — lấy từ danh bạ chùa, chỉ giữ phần cần để chọn.
nonisolated struct ILOrdinationPlaceEntity: Equatable, Identifiable {
    let id: String
    let name: String
    /// Địa chỉ ngắn hiển thị dưới tên (có thể rỗng).
    let subtitle: String
}
