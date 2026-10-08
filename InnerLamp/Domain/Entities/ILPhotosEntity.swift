//
//  ILPhotosEntity.swift
//  InnerLamp
//

import Foundation

/// Danh mục 1 ảnh trong gallery "Ảnh chùa đẹp" — khớp `cat` (1–4) trong design handoff
/// (`InnerLamp Prototype.dc.html`, `Component.PHOTOS`). `Tất cả` không phải là 1 danh mục của
/// ảnh mà là bộ lọc, nên được biểu diễn bằng `selectedCategory == nil` trên Entity.
nonisolated enum ILPhotosCategory: CaseIterable, Equatable {
    case temple        // Chùa
    case buddhaStatue  // Tượng Phật
    case meditation    // Cảnh thiền
    case festival      // Lễ hội
}

/// 1 ảnh trong gallery "Ảnh chùa đẹp" — nội dung từ `GET /v1/gallery` (danh tính, danh mục,
/// tiêu đề, địa điểm, URL ảnh).
nonisolated struct ILPhotosPhotoEntity: Equatable, Identifiable {
    let id: String
    let category: ILPhotosCategory
    let title: String
    let place: String
    /// Raw server URL of the 500 px thumbnail used by the grid; `nil` when the server sent none.
    let thumbnailURL: String?
    /// Raw server URL of the 1280 px image — carried for a future detail screen.
    let imageURL: String?
}

/// One page of the gallery. `hasMore == false` means the caller must stop requesting further
/// pages (`page >= total_pages`, or the server returned an empty page).
nonisolated struct ILPhotosPageEntity: Equatable {
    let items: [ILPhotosPhotoEntity]
    let page: Int
    let totalCount: Int
    let hasMore: Bool
}

/// Pure business entity cho màn Ảnh chùa đẹp — Domain layer only.
///
/// Chứa các ảnh đã tải, bộ lọc danh mục đang chọn (`nil` = Tất cả) và vị trí phân trang dùng cho
/// infinite scroll. Nhãn danh mục, phụ đề "N ảnh · Danh mục" và cờ `isLoadingMore` là UI state nên
/// nằm ở `ILPhotosStateModel`.
struct ILPhotosEntity: Equatable {
    var photos: [ILPhotosPhotoEntity] = []
    var selectedCategory: ILPhotosCategory? = nil
    /// Total photos on the server for the selected category (`total` of the paged response).
    var totalCount: Int = 0
    /// Last page fetched (1-based); `0` before the first page.
    var lastLoadedPage: Int = 0
    /// `false` once the server's last page was loaded, or a page came back empty.
    var hasMore: Bool = false

    static let empty = ILPhotosEntity()
}
