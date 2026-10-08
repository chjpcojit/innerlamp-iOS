//
//  ILBuddhistEventEntity.swift
//  InnerLamp
//

import Foundation

/// Truyền thống Phật giáo mà một sự kiện định kỳ thuộc về — khớp cột `tradition`
/// (`MAHAYANA` / `THERAVADA` / `UNIVERSAL`) trong bảng `buddhist_event_templates`.
///
/// Raw value dùng đúng chuỗi lưu trong Core Data; mọi mapping đều đi qua `rawValue`.
enum ILBuddhistTradition: String, Equatable, CaseIterable {
    case mahayana = "MAHAYANA"
    case theravada = "THERAVADA"
    case universal = "UNIVERSAL"
}

/// Phân loại một sự kiện định kỳ — khớp cột `category` (`MAJOR` / `COMMEMORATION` / `FOLK`) trong
/// bảng `buddhist_event_templates`. Khác `ILBuddhistTradition` (truyền thống nào tổ chức): đây là
/// loại sự kiện. Raw value dùng đúng chuỗi lưu trong Core Data.
enum ILBuddhistEventCategory: String, Equatable, CaseIterable {
    /// Đại lễ (Phật Đản, Vu Lan, Vesak, Thành đạo, Nhập Niết-bàn, Rằm tháng Giêng, vía Quán Thế Âm
    /// đản sinh / thành đạo / xuất gia).
    case major = "MAJOR"
    /// Vía và ngày kỷ niệm Phật giáo khác (vía Bồ Tát, An cư kiết hạ, Magha Puja, Kathina…).
    case commemoration = "COMMEMORATION"
    /// Tết dân gian Việt Nam — không phải lễ Phật giáo (Nguyên Đán, Hàn Thực, Đoan Ngọ, Trung Thu…).
    case folk = "FOLK"
}

/// Một sự kiện Phật giáo định kỳ hằng năm theo âm lịch (mẫu sự kiện, chưa gắn vào một năm cụ thể).
///
/// Chỉ chứa dữ liệu nghiệp vụ thô: `lunarDay` / `lunarMonth` là ngày/tháng âm lịch lặp lại mỗi
/// năm, `isLeapMonthEligible` quyết định sự kiện có được tính khi tháng âm đó là tháng nhuận hay
/// không. Việc chuyển `lunarDay`/`lunarMonth` sang một ngày dương lịch cụ thể là việc của
/// `ILBuddhistEventUseCase` (kết hợp với `ILLunarCalendar`).
struct ILBuddhistEventTemplateEntity: Equatable, Identifiable {
    /// Slug ổn định (vd `phat-dan`) — dùng làm khóa và id hiển thị.
    let id: String
    let title: String
    let eventDescription: String
    /// Ngày trong tháng âm lịch (1...30).
    let lunarDay: Int
    /// Tháng âm lịch (1...12).
    let lunarMonth: Int
    let tradition: ILBuddhistTradition
    let category: ILBuddhistEventCategory
    /// `true` nếu sự kiện vẫn diễn ra khi tháng âm lịch tương ứng là tháng nhuận.
    let isLeapMonthEligible: Bool
}

/// Một lần xuất hiện cụ thể của `ILBuddhistEventTemplateEntity` trên một ngày dương lịch.
///
/// Sinh ra khi ngày dương `date` đổi sang âm lịch trùng `lunarDay`/`lunarMonth` của template (và
/// thỏa quy tắc tháng nhuận). Đây là kết quả tính toán thuần túy — không được lưu, chỉ để hiển
/// thị trên lịch.
struct ILBuddhistEventOccurrenceEntity: Equatable {
    /// Ngày dương lịch sự kiện diễn ra.
    let date: Date
    /// Template đã sinh ra sự kiện này.
    let template: ILBuddhistEventTemplateEntity
}
