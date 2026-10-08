//
//  ILPostStateModel.swift
//  InnerLamp
//

import Foundation

/// Màu (tone) avatar của tác giả — enum thuần Foundation, được map sang `ILColors.Tone` ở tầng
/// View (không nhét UIKit token vào StateModel/ViewModel).
enum ILPostAuthorTone: Equatable {
    case gold
    case green
    case rose
}

/// 1 bình luận đã sẵn sàng hiển thị (thời gian tương đối, nhãn "Tán thán N", độ thụt lồng đã
/// tính sẵn).
struct ILPostCommentModel: Equatable, Identifiable {
    let id: String
    let authorName: String
    let authorInitials: String
    let timeText: String
    let text: String
    let tone: ILPostAuthorTone
    /// Nhãn hành động "Tán thán N" (số đã format).
    let likeText: String
    /// 0 = bình luận cấp cao nhất; 1 = trả lời (thụt `ILMetrics.commentIndent`).
    let depth: Int
}

/// Trạng thái UI của màn Bài đăng đạo tràng — do `ILPostViewModel` sở hữu, `ViewController` chỉ
/// đọc để render. Các chuỗi đã format (thời gian tương đối, "1.248 thành viên", "N lời chia sẻ")
/// nằm ở đây, không nằm trên `ILPostEntity` (xem `references/data_layer_boundaries.md`).
struct ILPostStateModel: Equatable {
    // Header (NavBar)
    var communityName: String = ""
    var memberCountText: String = ""

    // Thẻ bài đăng
    var authorName: String = ""
    var authorInitials: String = ""
    var authorTone: ILPostAuthorTone = .gold
    /// Dòng "2 giờ trước · Chia sẻ pháp".
    var metaText: String = ""
    var body: String = ""

    var isLiked: Bool = false
    var likeCountText: String = ""
    var commentCountText: String = ""

    // Mục bình luận
    var commentsHeaderText: String = ""
    var comments: [ILPostCommentModel] = []

    static let initial = ILPostStateModel()
}
