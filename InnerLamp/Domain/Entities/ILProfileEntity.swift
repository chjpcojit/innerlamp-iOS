//
//  ILProfileEntity.swift
//  InnerLamp
//

import Foundation

/// Gói dịch vụ hiện tại của người dùng.
enum ILProfilePlan: Equatable {
    case free
    case monthly
    case yearly
    case lifetime
}

/// Số liệu tu tập tích lũy — chỉ số thô, không format.
struct ILProfilePracticeStatsEntity: Equatable {
    /// Tổng số giờ tu tập.
    let totalHours: Int
    /// Số ngày tu tập liên tục hiện tại.
    let streakDays: Int
    /// Tổng số câu niệm Phật.
    let chantCount: Int
}

/// Nhóm dấu ấn — quyết định màu nhấn của huy hiệu ở tầng hiển thị.
enum ILProfileBadgeCategory: Equatable {
    /// Niệm Phật (vd. "108 tràng").
    case mala
    /// Giữ thời khóa liên tục (vd. "An cư 30 ngày").
    case streak
    /// Cúng dường / hồi hướng (vd. "Vu Lan").
    case offering
}

/// 1 dấu ấn tu tập đã đạt.
struct ILProfileBadgeEntity: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let category: ILProfileBadgeCategory
}

/// Chuông tỉnh thức đã đặt.
struct ILProfileReminderEntity: Equatable {
    let hour: Int
    let minute: Int
    /// Số ngày trong tuần chuông được bật (1...7).
    let activeDayCount: Int
}

/// Đạo tràng người dùng đang tham gia.
struct ILProfileCommunityEntity: Equatable {
    let id: String
    /// Tên ngắn, không kèm tiền tố "Đạo tràng" (vd. "Từ Quang").
    let name: String
}

/// Hồ sơ người dùng — chỉ dữ liệu nghiệp vụ, không có trạng thái UI hay chuỗi đã format.
struct ILProfileEntity: Equatable {
    var fullName: String = ""
    /// Rỗng khi người dùng chưa có pháp danh.
    var dharmaName: String = ""
    var practiceStats = ILProfilePracticeStatsEntity(totalHours: 0, streakDays: 0, chantCount: 0)
    /// Số mục nhật ký mỗi ngày trong cửa sổ gần đây, cũ → mới. 0 = ngày không ghi.
    var journalEntriesPerDay: [Int] = []
    /// Dấu ấn đạt gần đây, dùng để xem nhanh (không phải toàn bộ).
    var recentBadges: [ILProfileBadgeEntity] = []
    /// Tổng số dấu ấn trong hệ thống (kể cả chưa mở).
    var totalBadgeCount: Int = 0
    /// Số lần cúng dường.
    var offeringCount: Int = 0
    /// Số ngọn đèn Vu Lan đã thắp.
    var lanternCount: Int = 0
    var plan: ILProfilePlan = .free
    var reminder: ILProfileReminderEntity?
    var community: ILProfileCommunityEntity?

    static let empty = ILProfileEntity()
}
