//
//  ILPhotosStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chip danh mục lọc — `category == nil` là "Tất cả".
struct ILPhotosCategoryModel: Equatable, Identifiable {
    let id: String
    let label: String
    let category: ILPhotosCategory?
    let isSelected: Bool
}

/// 1 ảnh trong lưới gallery — bản sao presentation của `ILPhotosPhotoEntity`.
struct ILPhotosPhotoModel: Equatable, Identifiable {
    let id: String
    let title: String
    let place: String
    var thumbnailURL: String? = nil
    /// Raw server URL of the 1280 px image, shown by the photo viewer.
    var imageURL: String? = nil
    /// Localized category label, shown by the photo viewer.
    var categoryLabel: String = ""
}

/// UI state cho màn Ảnh chùa đẹp — Presentation layer, do `ILPhotosViewModel` sở hữu và cập nhật
/// độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị. Trạng thái
/// footer load-more được ViewController suy ra từ `isLoadingMore` / `hasMore`.
struct ILPhotosStateModel: Equatable {
    var categories: [ILPhotosCategoryModel] = []
    var photos: [ILPhotosPhotoModel] = []
    /// Phụ đề header ("86 ảnh" / "12 ảnh · Cảnh thiền") đã format sẵn, theo tổng của server.
    var subtitle: String = ""
    var isLoadingMore: Bool = false
    var hasMore: Bool = false

    static let initial = ILPhotosStateModel()
}
