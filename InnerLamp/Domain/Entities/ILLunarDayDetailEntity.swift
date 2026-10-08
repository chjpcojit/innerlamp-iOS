//
//  ILLunarDayDetailEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

/// Pure business entity cho màn "Chi tiết ngày âm" — Domain layer only.
///
/// Chứa toàn bộ dữ liệu lịch âm của 1 ngày dương (tính bằng `ILLunarCalendar`): ngày/tháng/năm
/// âm, Can Chi ngày, cờ Hoàng đạo/Hắc đạo, 6 giờ hoàng đạo, tuổi xung khắc, hướng xuất hành
/// (Hỷ thần/Tài thần/Hạc thần) và câu kinh trong ngày. KHÔNG chứa field chỉ phục vụ hiển thị (`*Error`,
/// nhãn `.localized`, format ngày) — những field đó nằm ở `ILLunarDayDetailStateModel`
/// (Presentation) và do `ILLunarDayDetailViewModel` chuyển đổi. Xem
/// `references/data_layer_boundaries.md`.
struct ILLunarDayDetailEntity: Equatable {
    /// Ngày dương đang xem (dùng lấy thứ trong tuần cho nhãn "Thứ …").
    let date: Date
    let solarDay: Int
    let solarMonth: Int
    let solarYear: Int

    let lunarDay: Int
    let lunarMonth: Int
    let lunarYear: Int
    let isLunarLeapMonth: Bool

    /// `true` = ngày Hoàng đạo (tốt), `false` = Hắc đạo (xấu) — xem `ILLunarCalendar.isHoangDao`.
    let isHoangDao: Bool

    /// Chỉ số Thiên Can & Địa Chi (0-based) của ngày — dùng cho tuổi xung khắc, nạp âm và lời
    /// giải thích ở phần "Ngũ hành & nạp âm".
    let dayCanIndex: Int
    let dayChiIndex: Int

    /// Chỉ số Địa Chi (0...11) của 6 giờ hoàng đạo trong ngày, theo thứ tự giờ trong ngày.
    let goodHourChiIndices: [Int]

    /// Chỉ số Địa Chi của tuổi xung khắc (chi đối xung với ngày).
    let clashChiIndex: Int

    /// Hướng Hỷ thần & Tài thần trong ngày (tên hướng đã resolve — fixed vocab tiếng Việt qua
    /// `.localized`, cùng cách `canChiYear`/`lunarMonthLabel`).
    let joyStarDirection: String
    let wealthStarDirection: String

    /// Hướng Hạc thần — hướng xấu cần TRÁNH khi xuất hành. `nil` khi Hạc thần "bận việc trên
    /// trời" (16/60 ngày Can Chi) — hôm đó không có hướng phải tránh.
    let craneStarDirection: String?

    /// Câu kinh/lời dạy trong ngày (nội dung, index theo `(lunarDay + lunarMonth) % 4`).
    let verseLines: [String]
    let verseSource: String
}
