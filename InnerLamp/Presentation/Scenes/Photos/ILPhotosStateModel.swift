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

/// 1 ảnh trong lưới gallery — bản sao presentation của `ILPhotosPhotoEntity`, kèm nhãn danh mục
/// đã format sẵn cho placeholder.
struct ILPhotosPhotoModel: Equatable, Identifiable {
    let id: String
    let title: String
    let place: String
    let imageHeight: Double
    let categoryLabel: String
}

/// UI state cho màn Ảnh chùa đẹp — Presentation layer, do `ILPhotosViewModel` sở hữu và cập nhật
/// độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị.
struct ILPhotosStateModel: Equatable {
    var categories: [ILPhotosCategoryModel] = []
    var photos: [ILPhotosPhotoModel] = []
    /// Phụ đề header ("12 ảnh" / "4 ảnh · Chùa") đã format sẵn.
    var subtitle: String = ""

    static let initial = ILPhotosStateModel()
}
