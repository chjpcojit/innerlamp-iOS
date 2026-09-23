//
//  ILSanghaEntity.swift
//  InnerLamp
//

import Foundation

/// Phiên thiền chung đang diễn ra — chỉ dữ liệu nghiệp vụ, không có trạng thái UI.
struct ILSanghaLiveSessionEntity: Equatable {
    /// Số người đang cùng ngồi thiền trên toàn quốc.
    let participantCount: Int
    let sessionMinutes: Int
}

/// Đạo tràng (chùa / nhóm tu học) mà người dùng đang tham gia.
struct ILSanghaCommunityEntity: Equatable {
    let id: String
    let name: String
    let memberCount: Int
    let district: String
    /// Thông báo mới nhất của đạo tràng (vd. lịch tụng kinh sắp tới).
    let announcement: String
}

/// 1 bài chia sẻ của bạn đồng tu.
struct ILSanghaPostEntity: Equatable {
    let id: String
    let authorName: String
    let postedAt: Date
    /// Số ngày tinh tấn liên tục của tác giả tại thời điểm đăng.
    let authorStreakDays: Int
    let body: String
    let likeCount: Int
    let replyCount: Int
}

struct ILSanghaEntity: Equatable {
    var liveSession: ILSanghaLiveSessionEntity?
    var community: ILSanghaCommunityEntity?
    var posts: [ILSanghaPostEntity] = []

    static let empty = ILSanghaEntity()
}
