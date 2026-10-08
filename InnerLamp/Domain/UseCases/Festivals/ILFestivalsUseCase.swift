//
//  ILFestivalsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILFestivalsUseCase {
    /// Các ngày lễ Phật giáo (lễ / vía Phật giáo từ catalog Core Data, cộng Rằm/Mùng Một là ngày trai giới)
    /// từ ngày 1/1 của năm chứa `date` đến hết 2 năm sau đó (3 năm dương lịch), gom theo tháng dương.
    /// Ngày đã qua có `daysUntil` âm.
    ///
    /// Tháng nào không có ngày lễ thì không xuất hiện trong kết quả.
    func loadMonths(from date: Date) async throws -> [ILFestivalMonthEntity]
}

final class ILFestivalsUseCaseImpl: ILFestivalsUseCase {

    private let buddhistEventUseCase: ILBuddhistEventUseCase

    init(buddhistEventUseCase: ILBuddhistEventUseCase) {
        self.buddhistEventUseCase = buddhistEventUseCase
    }

    func loadMonths(from date: Date) async throws -> [ILFestivalMonthEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let today = calendar.startOfDay(for: date)
        guard let rangeStart = calendar.date(from: DateComponents(year: calendar.component(.year, from: today), month: 1, day: 1)),
              let end = calendar.date(byAdding: .year, value: Self.yearsCovered, to: rangeStart) else {
            return []
        }

        // Lễ Phật giáo chung: bỏ Tết dân gian (`.folk`) và lễ Nam tông.
        let templates = try await buddhistEventUseCase.loadTemplates()
            .filter { $0.category != .folk && $0.tradition != .theravada }
        let occurrences = buddhistEventUseCase.occurrences(of: templates, from: rangeStart, to: end, calendar: calendar)
        let occurrencesByDay = Dictionary(grouping: occurrences) { calendar.startOfDay(for: $0.date) }

        var order: [String] = []
        var daysByMonth: [String: [ILFestivalDayEntity]] = [:]

        var day = rangeStart
        while day < end {
            let daysUntil = Self.daysBetween(today, day, calendar: calendar)

            if let dayOccurrences = occurrencesByDay[day] {
                for occurrence in dayOccurrences {
                    Self.append(
                        ILFestivalDayEntity(
                            id: "\(Self.dayKey(day, calendar: calendar))-\(occurrence.template.id)",
                            date: day,
                            title: occurrence.template.title,
                            kind: .festival,
                            daysUntil: daysUntil
                        ),
                        date: day,
                        calendar: calendar,
                        order: &order,
                        daysByMonth: &daysByMonth
                    )
                }
            } else {
                // Rằm / Mùng Một không có lễ riêng là ngày trai giới (kể cả trong tháng nhuận).
                let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
                let observanceKey: String? = switch lunar.day {
                case 1: "festivals.observance.newMoon"
                case 15: "festivals.observance.fullMoon"
                default: nil
                }
                if let observanceKey {
                    Self.append(
                        ILFestivalDayEntity(
                            id: Self.dayKey(day, calendar: calendar),
                            date: day,
                            title: String(format: observanceKey.localized, Self.lunarMonthName(lunar.month)),
                            kind: .observance,
                            daysUntil: daysUntil
                        ),
                        date: day,
                        calendar: calendar,
                        order: &order,
                        daysByMonth: &daysByMonth
                    )
                }
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

    /// Năm hiện tại + 2 năm sau.
    private static let yearsCovered = 3

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
