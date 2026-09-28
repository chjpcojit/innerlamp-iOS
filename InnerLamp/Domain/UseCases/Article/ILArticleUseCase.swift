//
//  ILArticleUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILArticleUseCase {
    /// Catalog 5 bài viết với bài `articleID` được chọn làm bài hiện tại.
    func getInitialState(articleID: String) -> ILArticleEntity

    /// Bài đang xem theo `currentArticleID` (`nil` nếu id không có trong catalog).
    func currentArticle(in entity: ILArticleEntity) -> ILArticleItemEntity?

    /// 2 bài "Đọc tiếp" ngay sau bài `currentID` theo thứ tự vòng quanh catalog.
    func nextArticles(after currentID: String, in entity: ILArticleEntity) -> [ILArticleItemEntity]

    /// Chuyển bài đang xem sang `id` (chạm 1 bài trong danh sách "Đọc tiếp").
    func selectArticle(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity

    /// Bật/tắt trạng thái đã lưu của bài `id` — thuần in-memory, chưa persist.
    func toggleSave(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity
}

final class ILArticleUseCaseImpl: ILArticleUseCase {

    // TODO: khi có API bài viết thật, thay catalog mock dưới đây bằng dữ liệu từ
    // networkService (danh mục "Bài viết Phật pháp hay", xem README design handoff — mục
    // "Data cần API"). Lưu bài hiện chỉ đổi trạng thái in-memory; khi có màn "Bài đã lưu"
    // thật cần persist `savedArticleIDs` xuống UserDefaultsService/Core Data.
    init() {}

    func getInitialState(articleID: String) -> ILArticleEntity {
        ILArticleEntity(articles: Self.makeArticleCatalog(), currentArticleID: articleID, savedArticleIDs: [])
    }

    func currentArticle(in entity: ILArticleEntity) -> ILArticleItemEntity? {
        entity.articles.first { $0.id == entity.currentArticleID }
    }

    func nextArticles(after currentID: String, in entity: ILArticleEntity) -> [ILArticleItemEntity] {
        guard !entity.articles.isEmpty,
              let index = entity.articles.firstIndex(where: { $0.id == currentID }) else {
            return []
        }
        return [1, 2].map { entity.articles[(index + $0) % entity.articles.count] }
    }

    func selectArticle(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity {
        guard entity.currentArticleID != id else { return entity }
        var updated = entity
        updated.currentArticleID = id
        return updated
    }

    func toggleSave(_ id: String, in entity: ILArticleEntity) -> ILArticleEntity {
        var updated = entity
        if updated.savedArticleIDs.contains(id) {
            updated.savedArticleIDs.remove(id)
        } else {
            updated.savedArticleIDs.insert(id)
        }
        return updated
    }

    // MARK: - Catalog

    /// Catalog tĩnh 5 bài viết khớp `Component.ARTICLES` trong design handoff (theo thứ tự
    /// `art-1` → `art-5`). Nội dung là dữ liệu hiển thị nên lấy qua `.localized`, giống cách
    /// `ILHomeUseCaseImpl` dựng danh mục bài viết ở Trang chủ.
    private static func makeArticleCatalog() -> [ILArticleItemEntity] {
        (0..<5).map { index in
            let prefix = "article.article.\(index)"
            return ILArticleItemEntity(
                id: "art-\(index + 1)",
                category: "\(prefix).category".localized,
                title: "\(prefix).title".localized,
                author: "\(prefix).author".localized,
                authorInitials: "\(prefix).initials".localized,
                date: "\(prefix).date".localized,
                readMinutes: Self.readMinutes[index],
                bodyParagraphs: Self.makeBodyParagraphs(index: index, prefix: prefix),
                quote: "\(prefix).quote".localized,
                quoteSource: "\(prefix).quoteSource".localized
            )
        }
    }

    private static func makeBodyParagraphs(index: Int, prefix: String) -> [String] {
        (0..<Self.bodyCounts[index]).map { "\(prefix).body.\($0)".localized }
    }

    /// Số phút đọc mỗi bài (khớp `read` của `Component.ARTICLES`).
    private static let readMinutes = [6, 4, 5, 5, 7]

    /// Số đoạn thân bài mỗi bài.
    private static let bodyCounts = [4, 3, 3, 3, 3]
}
