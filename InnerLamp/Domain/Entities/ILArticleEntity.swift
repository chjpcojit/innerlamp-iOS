//
//  ILArticleEntity.swift
//  InnerLamp
//

import Foundation

/// 1 bài viết Phật pháp (nội dung đầy đủ) — khớp `Component.ARTICLES` trong design handoff
/// (`InnerLamp Prototype.dc.html`, màn `article`). Đây là nội dung catalog tĩnh: tiêu đề, tác
/// giả, ngày đăng, các đoạn thân bài, câu trích dẫn và nguồn. Chưa có API bài viết thật (xem
/// TODO ở `ILArticleUseCaseImpl`).
struct ILArticleItemEntity: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    /// Chữ viết tắt tác giả hiển thị trong avatar ("MĐ", "TN", "IL") — là dữ liệu biên tập,
    /// không suy ra được từ tên tác giả (vd. "Ban biên tập InnerLamp" → "IL").
    let authorInitials: String
    /// Ngày đăng dạng chuỗi ("18 tháng 9") — nội dung tĩnh, không phải `Date`.
    let date: String
    /// Số phút đọc; chuỗi "N phút đọc" do `ILArticleViewModel` format khi map sang StateModel.
    let readMinutes: Int
    let bodyParagraphs: [String]
    let quote: String
    let quoteSource: String
}

/// Pure business entity cho màn Bài viết Phật pháp — Domain layer only.
///
/// Chỉ chứa catalog 5 bài viết, bài đang xem (`currentArticleID`) và tập id các bài đã lưu
/// (`savedArticleIDs`). Nhãn UI ("Lưu bài"/"Đã lưu"), chuỗi "N phút đọc" và thứ tự hiển thị là
/// UI state nên nằm ở `ILArticleStateModel` — xem `references/data_layer_boundaries.md`.
struct ILArticleEntity: Equatable {
    var articles: [ILArticleItemEntity] = []
    var currentArticleID: String = ""
    /// Các bài đã lưu — hiện là trạng thái in-memory (xem TODO persistence ở
    /// `ILArticleUseCaseImpl`), sẽ đồng bộ xuống UserDefaults khi có màn "Bài đã lưu" thật.
    var savedArticleIDs: Set<String> = []

    static let empty = ILArticleEntity()
}
