//
//  ILLunarCalendarUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILLunarCalendarUseCase {
    /// 6 tháng dương lịch bắt đầu từ tháng hiện tại, ngày âm tính bằng `ILLunarCalendar`,
    /// hôm nay đang được chọn.
    func getInitialState() -> ILLunarCalendarEntity

    /// Chọn 1 ngày trong các tháng đã nạp. `id` không thuộc tháng nào thì giữ nguyên `entity`.
    func selectDay(id: String, in entity: ILLunarCalendarEntity) -> ILLunarCalendarEntity

    /// Các ngày trai/mùng 1/rằm đầu tiên sau ngày đang chọn trong các tháng đã nạp (tối đa
    /// `limit` ngày, theo thứ tự thời gian).
    func upcomingSpecialDays(in entity: ILLunarCalendarEntity, limit: Int) -> [ILLunarCalendarDayEntity]
}

final class ILLunarCalendarUseCaseImpl: ILLunarCalendarUseCase {

    /// Số tháng carousel hiển thị (tháng hiện tại + 5 tháng sau) — khớp design handoff.
    static let monthCount = 6

    // Toàn bộ logic ở đây là tính toán thuần trên `ILLunarCalendar` (không network/disk). Lịch sự
    // kiện chùa/nhắc lịch cá nhân cần API nên chưa nằm trong scope — xem README của scene.
    private let calendar: Calendar
    private let now: () -> Date

    init(
        calendar: Calendar = Calendar(identifier: .gregorian),
        now: @escaping () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.now = now
    }

    func getInitialState() -> ILLunarCalendarEntity {
        let today = calendar.startOfDay(for: now())
        let currentMonthStart = firstDayOfMonth(containing: today)

        let months = (0..<Self.monthCount).compactMap { offset -> ILLunarCalendarMonthEntity? in
            guard let start = calendar.date(byAdding: .month, value: offset, to: currentMonthStart) else { return nil }
            return makeMonth(startingAt: start)
        }

        let todayID = dayID(for: today)
        return ILLunarCalendarEntity(months: months, todayID: todayID, selectedDayID: todayID)
    }

    func selectDay(id: String, in entity: ILLunarCalendarEntity) -> ILLunarCalendarEntity {
        guard entity.day(withID: id) != nil else { return entity }
        var updated = entity
        updated.selectedDayID = id
        return updated
    }

    func upcomingSpecialDays(in entity: ILLunarCalendarEntity, limit: Int) -> [ILLunarCalendarDayEntity] {
        guard limit > 0 else { return [] }
        let allDays = entity.months.flatMap(\.days)
        guard let selectedIndex = allDays.firstIndex(where: { $0.id == entity.selectedDayID }) else { return [] }
        return Array(allDays[(selectedIndex + 1)...].lazy.filter(\.isFastDay).prefix(limit))
    }

    // MARK: - Building months

    private func firstDayOfMonth(containing date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func makeMonth(startingAt start: Date) -> ILLunarCalendarMonthEntity? {
        let components = calendar.dateComponents([.year, .month], from: start)
        guard
            let year = components.year,
            let month = components.month,
            let dayRange = calendar.range(of: .day, in: .month, for: start)
        else { return nil }

        let days = dayRange.compactMap { day -> ILLunarCalendarDayEntity? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: start) else { return nil }
            let lunar = ILLunarCalendar.solarToLunar(day: day, month: month, year: year)
            return ILLunarCalendarDayEntity(
                id: dayID(for: date),
                date: date,
                solarDay: day,
                lunarDay: lunar.day,
                lunarMonth: lunar.month,
                isLunarLeapMonth: lunar.isLeapMonth,
                category: Self.category(
                    forLunarDay: lunar.day,
                    isLastDayOfShortMonth: ILLunarCalendar.isLastDayOfShortMonth(lunar, on: date, calendar: calendar)
                ),
                isHoangDao: ILLunarCalendar.isHoangDao(
                    solarDay: day,
                    solarMonth: month,
                    solarYear: year,
                    lunarMonth: lunar.month
                )
            )
        }

        let midLunar = ILLunarCalendar.solarToLunar(day: 15, month: month, year: year)
        let weekdayOfFirst = calendar.component(.weekday, from: start) // 1 = Chủ nhật

        return ILLunarCalendarMonthEntity(
            id: String(format: "%04d-%02d", year, month),
            solarMonth: month,
            solarYear: year,
            leadingBlankDays: weekdayOfFirst - 1,
            days: days,
            midLunarMonth: midLunar.month,
            midLunarYear: midLunar.year,
            isMidLunarLeapMonth: midLunar.isLeapMonth
        )
    }

    private func dayID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// Ngày trai theo design handoff: 1, 8, 14, 15, 18, 23, 30 âm lịch (mùng 1 và rằm có nhãn
    /// riêng). Tháng thiếu (29 ngày) không có ngày 30 nên ngày cuối tháng (29) thay thế ngày trai 30.
    private static let otherFastLunarDays: Set<Int> = [8, 14, 18, 23, 30]

    static func category(
        forLunarDay lunarDay: Int,
        isLastDayOfShortMonth: Bool = false
    ) -> ILLunarCalendarDayCategory {
        switch lunarDay {
        case 1: return .newMoon
        case 15: return .fullMoon
        case let day where otherFastLunarDays.contains(day): return .fastDay
        case 29 where isLastDayOfShortMonth: return .fastDay
        default: return .ordinary
        }
    }
}
