//
//  ILFestivalsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILFestivalsUseCase {
    /// Các ngày lễ Phật giáo của đúng một năm dương lịch `year` (từ 1/1 đến 31/12) lấy từ server
    /// (`GET /v1/calendar/events?year=`), cộng Rằm/Mùng Một không có lễ riêng là ngày trai giới,
    /// gom theo tháng dương. `today` là mốc tính `daysUntil` (ngày đã qua có `daysUntil` âm) và
    /// quyết định nhãn tháng có kèm năm hay không.
    ///
    /// Tháng nào không có ngày lễ thì không xuất hiện trong kết quả. Lỗi mạng/server được ném ra
    /// dưới dạng `ILCatalogError`.
    func loadMonths(year: Int, today date: Date) async throws -> [ILFestivalMonthEntity]
}

final class ILFestivalsUseCaseImpl: ILFestivalsUseCase {

    private let calendarEventRepository: ILCalendarEventRepository

    init(calendarEventRepository: ILCalendarEventRepository) {
        self.calendarEventRepository = calendarEventRepository
    }

    func loadMonths(year: Int, today date: Date) async throws -> [ILFestivalMonthEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let today = calendar.startOfDay(for: date)
        guard let rangeStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(byAdding: .year, value: 1, to: rangeStart) else {
            return []
        }

        // Ngày dương và âm lịch của lễ do server tính; client chỉ gom nhóm theo ngày.
        let calendarEvents = try await calendarEventRepository.loadEvents(year: year)
        let eventsByCode = Dictionary(calendarEvents.events.map { ($0.code, $0) }) { first, _ in first }
        let occurrencesByDay = Dictionary(grouping: calendarEvents.occurrences) {
            calendar.startOfDay(for: $0.solarDate)
        }

        var order: [String] = []
        var daysByMonth: [String: [ILFestivalDayEntity]] = [:]

        var day = rangeStart
        while day < end {
            let daysUntil = Self.daysBetween(today, day, calendar: calendar)

            if let dayOccurrences = occurrencesByDay[day] {
                for occurrence in dayOccurrences {
                    guard let event = eventsByCode[occurrence.eventCode] else { continue }
                    Self.append(
                        ILFestivalDayEntity(
                            id: "\(Self.dayKey(day, calendar: calendar))-\(event.code)",
                            date: day,
                            title: event.name,
                            kind: .festival,
                            daysUntil: daysUntil,
                            lunarDay: occurrence.lunarDay,
                            lunarMonth: occurrence.lunarMonth,
                            isLeapMonth: occurrence.isLeapMonth,
                            eventCode: event.code
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
                            daysUntil: daysUntil,
                            lunarDay: lunar.day,
                            lunarMonth: lunar.month,
                            isLeapMonth: lunar.isLeapMonth
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
