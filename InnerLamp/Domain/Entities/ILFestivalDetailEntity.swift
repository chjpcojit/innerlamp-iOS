//
//  ILFestivalDetailEntity.swift
//  InnerLamp
//

import Foundation

/// 1 ngày lễ Phật giáo cụ thể trong màn "Chi tiết ngày lễ" — Domain layer.
///
/// Ghép nội dung của sự kiện (`GET /v1/calendar/events` → `events`) với đúng lần xuất hiện
/// (`occurrences`) mà người dùng đã chạm. Chỉ chứa giá trị thô từ server; chuỗi hiển thị (đếm
/// ngược, thứ ngày, ngày âm) do `ILFestivalDetailViewModel` format. Text trống nghĩa là server
/// chưa có nội dung — ViewModel quyết định hiện "chưa có" thay vì ẩn mục.
struct ILFestivalDetailEntity: Equatable {
    /// Mã sự kiện trên server (vd `vu-lan`).
    let code: String
    let name: String
    let shortDescription: String
    let longDescription: String
    /// Hướng dẫn thực hành ("Phật tử thường làm gì"); mỗi dòng là 1 việc. Có thể rỗng.
    let guidance: String
    /// `nil` cho tới khi chủ nội dung cung cấp ảnh.
    let imageURL: String?
    /// Tên các nhóm của sự kiện ("Phật giáo", "Dân gian"…), theo thứ tự hiển thị.
    let groupNames: [String]
    /// Ngày dương lịch (đầu ngày) của lần xuất hiện này.
    let date: Date
    let lunarDay: Int
    let lunarMonth: Int
    let isLeapMonth: Bool
    /// Số ngày còn lại kể từ hôm nay (0 = hôm nay, âm = đã qua).
    let daysUntil: Int
}
