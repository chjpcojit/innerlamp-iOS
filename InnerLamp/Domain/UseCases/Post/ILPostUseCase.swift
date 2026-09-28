//
//  ILPostUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILPostUseCase {
    /// Dựng entity cho bài `postID` (fallback về bài đầu tiên nếu id không có trong catalog,
    /// khớp `curPost = Component.POSTS[s.postIdx] || Component.POSTS[0]` của prototype).
    func getInitialState(postID: String) -> ILPostEntity

    /// Bật/tắt trạng thái đã tán thán bài — thuần in-memory, chưa persist.
    func toggleLike(in entity: ILPostEntity) -> ILPostEntity
}

final class ILPostUseCaseImpl: ILPostUseCase {

    // TODO: khi có API bài đăng + bình luận thật (danh mục "Chia sẻ của bạn đồng tu", xem README
    // design handoff — mục "Data cần API"), thay catalog mock bên dưới bằng ILPostRepository →
    // networkService. Tán thán hiện chỉ đổi trạng thái in-memory; khi có API thật cần gửi/gỡ
    // like và persist.
    init() {}

    func getInitialState(postID: String) -> ILPostEntity {
        let posts = Self.makePostCatalog()
        // Catalog luôn có 5 bài nên `posts[0]` an toàn (không phải force unwrap `!`).
        let post = posts.first { $0.id == postID } ?? posts[0]
        return ILPostEntity(post: post, comments: Self.makeComments(), isLiked: false)
    }

    func toggleLike(in entity: ILPostEntity) -> ILPostEntity {
        var updated = entity
        updated.isLiked.toggle()
        return updated
    }

    // MARK: - Catalog

    /// Catalog tĩnh 5 bài đăng khớp `Component.POSTS` trong design handoff (theo thứ tự
    /// `post-1` → `post-5`). Nội dung là dữ liệu hiển thị nên lấy qua `.localized`, giống cách
    /// `ILArticleUseCaseImpl` dựng catalog bài viết.
    private static func makePostCatalog() -> [ILPostItemEntity] {
        let offsets: [TimeInterval] = [-2 * 3600, -5 * 3600, -24 * 3600, -26 * 3600, -48 * 3600]
        let likeCounts = [318, 204, 512, 96, 187]
        let commentCounts = [24, 17, 41, 33, 12]
        let memberCounts = [1248, 1248, 3960, 1248, 1248]

        return (0..<5).map { index in
            let prefix = "post.post.\(index)"
            return ILPostItemEntity(
                id: "post-\(index + 1)",
                authorName: "\(prefix).author".localized,
                authorInitials: "\(prefix).initials".localized,
                postedAt: Date().addingTimeInterval(offsets[index]),
                tag: "\(prefix).tag".localized,
                body: "\(prefix).body".localized,
                likeCount: likeCounts[index],
                commentCount: commentCounts[index],
                communityName: "\(prefix).community".localized,
                communityMemberCount: memberCounts[index]
            )
        }
    }

    /// 3 bình luận mẫu khớp `comments` trong design handoff (2 bình luận cấp cao nhất + 1 trả lời
    /// lồng vào bình luận đầu tiên).
    private static func makeComments() -> [ILPostCommentEntity] {
        let offsets: [TimeInterval] = [-3600, -48 * 60, -30 * 60]
        let likeCounts = [12, 5, 9]
        let parentIDs: [String?] = [nil, nil, "post-comment-1"]

        return (0..<3).map { index in
            let prefix = "post.comment.\(index)"
            return ILPostCommentEntity(
                id: "post-comment-\(index + 1)",
                authorName: "\(prefix).author".localized,
                authorInitials: "\(prefix).initials".localized,
                postedAt: Date().addingTimeInterval(offsets[index]),
                text: "\(prefix).text".localized,
                likeCount: likeCounts[index],
                parentID: parentIDs[index]
            )
        }
    }
}
