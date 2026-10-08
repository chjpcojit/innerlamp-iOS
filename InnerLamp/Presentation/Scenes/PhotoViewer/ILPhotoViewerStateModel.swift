//
//  ILPhotoViewerStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 ảnh trong màn xem ảnh — snapshot presentation do coordinator dựng từ danh sách đang hiển thị
/// ở lưới (`ILPhotosPhotoModel`), nên màn này không tự gọi API.
struct ILPhotoViewerItemModel: Equatable, Identifiable {
    let id: String
    let title: String
    let place: String
    /// Nhãn danh mục đã localize (viewer tự in hoa cho eyebrow).
    let categoryLabel: String
    /// Raw server URL of the 1280 px image; `nil` shows only the placeholder.
    let imageURL: String?
}

/// 3 nút hành động dưới ảnh.
enum ILPhotoViewerAction: Equatable, CaseIterable {
    case save
    case setWallpaper
    case share
}

/// `heroID` dùng chung giữa ô ảnh ở lưới và ảnh lớn ở viewer để `HeroTransition` morph.
enum ILPhotoViewerHeroID {
    static func make(photoID: String) -> String { "photo-\(photoID)" }
}

/// UI state cho màn xem ảnh — Presentation layer, do `ILPhotoViewerViewModel` sở hữu.
struct ILPhotoViewerStateModel: Equatable {
    var item: ILPhotoViewerItemModel
    /// "3 / 12" đã format sẵn.
    var counter: String
    var hasPrevious: Bool
    var hasNext: Bool
    var isFavorite: Bool
    /// Thông báo ngắn dưới các nút; rỗng = không hiện.
    var toast: String = ""
}
