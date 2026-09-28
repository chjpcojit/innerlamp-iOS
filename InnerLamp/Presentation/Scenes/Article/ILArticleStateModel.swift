//
//  ILArticleStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 hàng trong danh sách "Đọc tiếp" — bản sao presentation của `ILArticleItemEntity`, kèm nhãn
/// danh mục đã viết hoa (eyebrow) cho `ViewController`.
struct ILArticleNextArticleModel: Equatable, Identifiable {
    let id: String
    let categoryLabel: String
    let title: String
}

/// UI state cho màn Bài viết Phật pháp — Presentation layer, do `ILArticleViewModel` sở hữu và
/// cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị.
/// Các chuỗi đã format ("N phút đọc", nhãn nút Lưu/Đã lưu) nằm ở đây, không nằm trên
/// `ILArticleEntity` (xem `references/data_layer_boundaries.md`).
struct ILArticleStateModel: Equatable {
    /// Tiêu đề + phụ đề dải header (danh mục + "N phút đọc").
    var headerCategory: String = ""
    var headerReadText: String = ""

    var title: String = ""
    var author: String = ""
    var authorInitials: String = ""
    /// Dòng "18 tháng 9 · 6 phút đọc" dưới tên tác giả.
    var dateReadText: String = ""

    var bodyParagraphs: [String] = []
    var quote: String = ""
    var quoteSource: String = ""

    var isSaved: Bool = false
    var saveButtonTitle: String = ""
    var shareButtonTitle: String = ""

    var readMoreTitle: String = ""
    var nextArticles: [ILArticleNextArticleModel] = []

    static let initial = ILArticleStateModel()
}
