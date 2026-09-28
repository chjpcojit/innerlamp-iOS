//
//  ILLibraryEntity.swift
//  InnerLamp
//

import Foundation

/// Loại nội dung trong Thư viện — khớp 3 nhóm lọc (Kinh văn / Thiền dẫn / Pháp thoại) trong
/// design handoff (`InnerLamp Prototype.dc.html`, `isLib`).
enum ILLibraryContentKind: Equatable, CaseIterable {
    case sutra
    case meditation
    case talk
}

/// Màu nhấn của 1 hàng nội dung. Domain không import UIKit nên map sang `ILColors.Tone` ở tầng
/// ViewController (cùng quy ước với `ILHomeSessionTone`).
enum ILLibraryTone: Equatable {
    case gold
    case green
    case rose
    case ink
}

/// 1 mục nội dung (kinh, thiền dẫn, pháp thoại) — chỉ dữ liệu nghiệp vụ, không có trạng thái UI.
struct ILLibraryItemEntity: Equatable {
    let id: String
    let kind: ILLibraryContentKind
    let title: String
    let subtitle: String
    let durationMinutes: Int
    let tone: ILLibraryTone
}

/// Thẻ nổi bật đầu trang (vd. "Pháp thoại mùa Vu Lan").
struct ILLibraryFeaturedEntity: Equatable {
    let id: String
    let eyebrow: String
    let title: String
    let durationMinutes: Int
}

struct ILLibraryEntity: Equatable {
    var featured: ILLibraryFeaturedEntity?
    var items: [ILLibraryItemEntity] = []
    /// Carousel "Chư Phật & Bồ Tát" — bản tóm tắt, dùng chung `ILHomeDeityEntity` (map từ
    /// `ILDeityUseCase.getAllDeities()`) với carousel cùng nội dung ở Trang chủ.
    var deities: [ILHomeDeityEntity] = []

    static let empty = ILLibraryEntity()
}
