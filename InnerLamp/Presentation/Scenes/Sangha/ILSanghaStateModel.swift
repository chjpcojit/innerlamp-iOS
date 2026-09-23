//
//  ILSanghaStateModel.swift
//  InnerLamp
//

import Foundation

/// Thẻ "Đang cùng ngồi thiền" đã sẵn sàng hiển thị (số đã format, câu phụ đã ghép).
struct ILSanghaLiveSessionModel: Equatable {
    let title: String
    let countText: String
    let captionText: String
    let ctaTitle: String
}

/// Thẻ "Đạo tràng của tôi" đã sẵn sàng hiển thị.
struct ILSanghaCommunityModel: Equatable {
    let id: String
    let name: String
    let metaText: String
    let announcement: String
}

/// 1 bài chia sẻ đã sẵn sàng hiển thị (thời gian, tinh tấn, tùy hỷ / hồi âm đã format).
struct ILSanghaPostModel: Equatable {
    let id: String
    let authorName: String
    let authorInitials: String
    let metaText: String
    let body: String
    let likeText: String
    let replyText: String
}

/// Trạng thái UI của màn Đạo tràng — do `ILSanghaViewModel` sở hữu, `ViewController` chỉ đọc để render.
struct ILSanghaStateModel: Equatable {
    var liveSession: ILSanghaLiveSessionModel?
    var community: ILSanghaCommunityModel?
    var posts: [ILSanghaPostModel] = []

    var hasPosts: Bool { !posts.isEmpty }

    static let initial = ILSanghaStateModel()
}
