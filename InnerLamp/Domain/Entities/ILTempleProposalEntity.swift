//
//  ILTempleProposalEntity.swift
//  InnerLamp
//

import Foundation

/// Chùa người dùng đề xuất thêm vào danh bạ ("Thêm thông tin chùa") — chờ InnerLamp duyệt.
nonisolated struct ILTempleProposalEntity: Equatable {
    let name: String
    let province: String
    /// Địa chỉ cụ thể — không bắt buộc, rỗng nếu người dùng không biết.
    let address: String
}
