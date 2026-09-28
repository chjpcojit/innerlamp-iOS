//
//  ILPhotosEntity.swift
//  InnerLamp
//

import Foundation

/// Danh mục 1 ảnh trong gallery "Ảnh chùa đẹp" — khớp `cat` (1–4) trong design handoff
/// (`InnerLamp Prototype.dc.html`, `Component.PHOTOS`). `Tất cả` không phải là 1 danh mục của
/// ảnh mà là bộ lọc, nên được biểu diễn bằng `selectedCategory == nil` trên Entity.
enum ILPhotosCategory: CaseIterable, Equatable {
    case temple        // Chùa
    case buddhaStatue  // Tượng Phật
    case meditation    // Cảnh thiền
    case festival      // Lễ hội
}

/// 1 ảnh trong gallery "Ảnh chùa đẹp" — nội dung catalog (danh tính, danh mục, tiêu đề, địa điểm,
/// chiều cao hiển thị). Chưa có API ảnh thật (xem TODO ở `ILPhotosUseCaseImpl`).
struct ILPhotosPhotoEntity: Equatable, Identifiable {
    let id: String
    let category: ILPhotosCategory
    let title: String
    let place: String
    /// Chiều cao ô ảnh (điểm) trong lưới 2 cột — dữ liệu tỷ lệ hiển thị đi kèm ảnh, sau này sẽ
    /// thay bằng kích thước ảnh thật từ phía sản phẩm.
    let imageHeight: Double
}

/// Pure business entity cho màn Ảnh chùa đẹp — Domain layer only.
///
/// Chỉ chứa catalog ảnh và bộ lọc danh mục đang chọn (`nil` = Tất cả). Nhãn danh mục, chuỗi
/// phụ đề "N ảnh · Danh mục" và thứ tự hiển thị là UI state nên nằm ở `ILPhotosStateModel` —
/// xem `references/data_layer_boundaries.md`.
struct ILPhotosEntity: Equatable {
    var photos: [ILPhotosPhotoEntity] = []
    var selectedCategory: ILPhotosCategory? = nil

    static let empty = ILPhotosEntity()
}
