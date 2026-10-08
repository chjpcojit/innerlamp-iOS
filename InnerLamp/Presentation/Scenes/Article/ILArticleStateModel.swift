//
//  ILArticleStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 hàng trong danh sách "Đọc tiếp" — bản sao presentation của `ILArticleSummaryEntity`, kèm
/// nhãn danh mục đã viết hoa (eyebrow) cho `ViewController`.
struct ILArticleNextArticleModel: Equatable, Identifiable {
    let id: String
    let categoryLabel: String
    let title: String
}

/// UI state cho màn Bài viết Phật pháp — Presentation layer, do `ILArticleViewModel` sở hữu và
/// cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để hiển thị.
/// Các chuỗi đã format ("N phút đọc", ngày đăng, nhãn nút Lưu/Đã lưu, "Nguồn: …") nằm ở đây,
/// không nằm trên `ILArticleEntity`.
struct ILArticleStateModel: Equatable {
    /// Tiêu đề + phụ đề dải header (danh mục + "N phút đọc").
    var headerCategory: String = ""
    var headerReadText: String = ""
    /// URL ảnh hero đúng như API trả về; `nil` thì hero chỉ hiện placeholder.
    var heroImageURL: String?

    var title: String = ""
    var author: String = ""
    var authorInitials: String = ""
    /// Dòng "18 tháng 9 · 6 phút đọc" dưới tên tác giả; chỉ còn "6 phút đọc" khi bài không có
    /// ngày đăng.
    var dateReadText: String = ""

    var bodyParagraphs: [String] = []
    var quote: String = ""
    var quoteSource: String = ""

    /// Dòng "Nguồn: Báo Giác Ngộ" — rỗng khi bài không có tên nguồn.
    var sourceText: String = ""
    /// Link bài gốc; `nil` thì dòng nguồn chỉ hiển thị, không chạm được.
    var sourceURL: String?

    var isSaved: Bool = false
    var saveButtonTitle: String = ""
    var shareButtonTitle: String = ""

    var readMoreTitle: String = ""
    var nextArticles: [ILArticleNextArticleModel] = []

    static let initial = ILArticleStateModel()
}
