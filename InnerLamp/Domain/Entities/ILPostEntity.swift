//
//  ILPostEntity.swift
//  InnerLamp
//

import Foundation

/// 1 bình luận trong bài đăng đạo tràng — chỉ dữ liệu nghiệp vụ, không có trạng thái UI.
struct ILPostCommentEntity: Equatable, Identifiable {
    let id: String
    let authorName: String
    /// Chữ viết tắt tác giả hiển thị trong avatar ("HL", "MT", "TN") — là dữ liệu biên tập,
    /// không suy ra được từ tên tác giả (khớp `Component.POSTS` / bình luận trong design handoff).
    let authorInitials: String
    let postedAt: Date
    let text: String
    let likeCount: Int
    /// id bình luận cha; nil cho bình luận cấp cao nhất (bình luận con thụt 22px khi render).
    let parentID: String?
}

/// 1 bài đăng đạo tràng (nội dung đầy đủ) — khớp `Component.POSTS` trong design handoff
/// (`InnerLamp Prototype.dc.html`, màn `post`). Nội dung catalog tĩnh; chưa có API bài đăng thật
/// (xem TODO ở `ILPostUseCaseImpl`).
struct ILPostItemEntity: Equatable, Identifiable {
    let id: String
    let authorName: String
    /// Chữ viết tắt tác giả hiển thị trong avatar ("TN", "DH", "MĐ"...) — dữ liệu biên tập.
    let authorInitials: String
    let postedAt: Date
    /// Nhãn phân loại bài ("Chia sẻ pháp", "Nhật ký tu tập", "Hỏi đáp"...).
    let tag: String
    let body: String
    let likeCount: Int
    /// Tổng số bình luận (lớn hơn số bình luận mẫu được render, khớp prototype).
    let commentCount: Int
    /// Tên đạo tràng hiển thị trên header (khớp `curPost.where`).
    let communityName: String
    /// Số thành viên đạo tràng (khớp `curPost.whereSub`).
    let communityMemberCount: Int
}

/// Pure business entity cho màn Bài đăng đạo tràng — Domain layer only.
///
/// Chỉ chứa bài đang xem, danh sách bình luận và trạng thái đã tán thán (`isLiked`). Mọi thứ
/// format hiển thị ("2 giờ trước · tag", "1.248 thành viên", "Tán thán 12") là UI state nên nằm
/// ở `ILPostStateModel` — xem `references/data_layer_boundaries.md`.
struct ILPostEntity: Equatable {
    let post: ILPostItemEntity
    let comments: [ILPostCommentEntity]
    /// Trạng thái tán thán của người dùng với bài — hiện in-memory, chưa persist (xem TODO
    /// `ILPostUseCaseImpl`).
    var isLiked: Bool
}
