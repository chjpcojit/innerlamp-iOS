//
//  ILFestivalsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILFestivalsUseCase {
    /// Tính các ngày lễ Phật giáo (lễ lớn, vía, Rằm/Mùng Một — ngày trai giới) trong 12 tháng
    /// dương lịch kể từ `date`, gom theo tháng dương.
    ///
    /// Tháng nào không có ngày lễ thì không xuất hiện trong kết quả. Giữ `async throws` để sau này
    /// thay catalog tĩnh bằng API lịch lễ thật mà không đổi hợp đồng.
    func loadMonths(from date: Date) async throws -> [ILFestivalMonthEntity]
}

final class ILFestivalsUseCaseImpl: ILFestivalsUseCase {

    /// Danh mục lễ chung theo design handoff (`LEVENTS` trong `InnerLamp Prototype.dc.html`) —
    /// khóa `lunarDay*100 + lunarMonth` → key localize tên lễ. Cố ý hẹp hơn catalog Core Data của
    /// `ILBuddhistEventUseCase` (không gồm Tết dân gian / lễ Nam tông): màn này chỉ hiện lễ Phật
    /// giáo chung, và các Rằm không có tên lễ riêng hiện thành "ngày trai giới".
    private static let festivalTitleKeys: [Int: String] = [
        1 * 100 + 1: "festivals.event.1_1",
        15 * 100 + 1: "festivals.event.15_1",
        8 * 100 + 2: "festivals.event.8_2",
        15 * 100 + 2: "festivals.event.15_2",
        19 * 100 + 2: "festivals.event.19_2",
        21 * 100 + 2: "festivals.event.21_2",
        4 * 100 + 4: "festivals.event.4_4",
        15 * 100 + 4: "festivals.event.15_4",
        16 * 100 + 4: "festivals.event.16_4",
        19 * 100 + 6: "festivals.event.19_6",
        13 * 100 + 7: "festivals.event.13_7",
        15 * 100 + 7: "festivals.event.15_7",
        30 * 100 + 7: "festivals.event.30_7",
        22 * 100 + 8: "festivals.event.22_8",
        19 * 100 + 9: "festivals.event.19_9",
        30 * 100 + 9: "festivals.event.30_9",
        5 * 100 + 10: "festivals.event.5_10",
        17 * 100 + 11: "festivals.event.17_11",
        8 * 100 + 12: "festivals.event.8_12"
    ]

    /// Chùa tổ chức mẫu theo design handoff: `tp-tuquang` (Từ Quang) luôn đứng đầu, 8 chùa còn lại
    /// theo catalog "Chùa Việt Nam" (`Component.TEMPLES` trong prototype).
    private static let templeIDs = [
        "tp-tuquang", "tp-motcot", "tp-tranquoc", "tp-huong", "tp-baidinh",
        "tp-thienmu", "tp-linhung", "tp-truclam", "tp-vinhnghiem"
    ]

    /// Các ngày lễ lớn (BIG) trong prototype — khóa `lunarDay*100 + lunarMonth`. Cả 9 chùa đều tổ
    /// chức. `['15/1','15/2','19/2','15/4','19/6','15/7','19/9','8/12']`.
    private static let majorKeys: Set<Int> = [
        15 * 100 + 1, 15 * 100 + 2, 19 * 100 + 2, 15 * 100 + 4,
        19 * 100 + 6, 15 * 100 + 7, 19 * 100 + 9, 8 * 100 + 12
    ]

    func loadMonths(from date: Date) async throws -> [ILFestivalMonthEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let today = calendar.startOfDay(for: date)
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let end = calendar.date(byAdding: .month, value: 12, to: currentMonthStart) else {
            return []
        }

        var order: [String] = []
        var daysByMonth: [String: [ILFestivalDayEntity]] = [:]

        var day = today
        while day < end {
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            let key = lunar.day * 100 + lunar.month

            // Lễ không lặp lại trong tháng nhuận — ngày 1/15 của tháng nhuận vẫn là ngày trai giới.
            if let titleKey = Self.festivalTitleKeys[key], !lunar.isLeapMonth {
                let kind = Self.majorKeys.contains(key) ? ILFestivalKind.major : .festival
                Self.append(
                    ILFestivalDayEntity(
                        id: Self.dayKey(day, calendar: calendar),
                        date: day,
                        title: titleKey.localized,
                        kind: kind,
                        daysUntil: Self.daysBetween(today, day, calendar: calendar),
                        hostTempleIDs: Self.hostTempleIDs(for: kind, key: key)
                    ),
                    date: day,
                    calendar: calendar,
                    order: &order,
                    daysByMonth: &daysByMonth
                )
            } else if lunar.day == 1 {
                let title = String(format: "festivals.observance.newMoon".localized, Self.lunarMonthName(lunar.month))
                Self.append(
                    ILFestivalDayEntity(
                        id: Self.dayKey(day, calendar: calendar),
                        date: day,
                        title: title,
                        kind: .observance,
                        daysUntil: Self.daysBetween(today, day, calendar: calendar),
                        hostTempleIDs: [Self.templeIDs[0]]
                    ),
                    date: day,
                    calendar: calendar,
                    order: &order,
                    daysByMonth: &daysByMonth
                )
            } else if lunar.day == 15 {
                let title = String(format: "festivals.observance.fullMoon".localized, Self.lunarMonthName(lunar.month))
                Self.append(
                    ILFestivalDayEntity(
                        id: Self.dayKey(day, calendar: calendar),
                        date: day,
                        title: title,
                        kind: .observance,
                        daysUntil: Self.daysBetween(today, day, calendar: calendar),
                        hostTempleIDs: [Self.templeIDs[0]]
                    ),
                    date: day,
                    calendar: calendar,
                    order: &order,
                    daysByMonth: &daysByMonth
                )
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let currentYear = calendar.component(.year, from: today)
        return order.compactMap { monthKey in
            guard let days = daysByMonth[monthKey], let first = days.first else { return nil }
            let month = calendar.component(.month, from: first.date)
            let year = calendar.component(.year, from: first.date)
            let label = year == currentYear
                ? String(format: "festivals.month.label".localized, month)
                : String(format: "festivals.month.labelYear".localized, month, year)
            return ILFestivalMonthEntity(id: monthKey, label: label, days: days)
        }
    }

    // MARK: - Helpers

    /// Chùa tổ chức theo loại ngày — lễ lớn: cả 9 chùa; vía: Từ Quang + 2 chùa (xác định theo
    /// khóa ngày âm); ngày trai giới: chỉ Từ Quang. Dữ liệu mẫu, bản thật lấy từ sự kiện chùa
    /// đăng ký (xem TODO ở `ILHomeUseCaseImpl`).
    private static func hostTempleIDs(for kind: ILFestivalKind, key: Int) -> [String] {
        switch kind {
        case .major:
            return templeIDs
        case .festival:
            let h = key % 97
            return [templeIDs[0], templeIDs[1 + h % 8], templeIDs[1 + (h + 3) % 8]]
        case .observance:
            return [templeIDs[0]]
        }
    }

    private static func append(
        _ entity: ILFestivalDayEntity,
        date: Date,
        calendar: Calendar,
        order: inout [String],
        daysByMonth: inout [String: [ILFestivalDayEntity]]
    ) {
        let monthKey = monthKey(date, calendar: calendar)
        if daysByMonth[monthKey] == nil { order.append(monthKey) }
        daysByMonth[monthKey, default: []].append(entity)
    }

    /// Tên tháng âm ngắn ("Giêng", "Bảy"…) — tái dùng bộ `lunarCalendar.month.*`.
    private static func lunarMonthName(_ month: Int) -> String {
        "lunarCalendar.month.\(max(1, min(12, month)))".localized
    }

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private static func monthKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
