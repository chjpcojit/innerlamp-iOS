//
//  ILFestivalDetailUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILFestivalDetailUseCase {
    /// Chi tiết lần xuất hiện của sự kiện `code` vào ngày dương `date`, lấy từ
    /// `GET /v1/calendar/events?year=` của năm chứa `date`. `today` là mốc tính `daysUntil`.
    ///
    /// Lỗi mạng/server được ném ra dưới dạng `ILCatalogError`; sự kiện (hoặc lần xuất hiện vào
    /// đúng ngày đó) không có trong phản hồi → `ILCatalogError.notFound`.
    func loadDetail(code: String, date: Date, today: Date) async throws -> ILFestivalDetailEntity
}

final class ILFestivalDetailUseCaseImpl: ILFestivalDetailUseCase {

    private let calendarEventRepository: ILCalendarEventRepository

    init(calendarEventRepository: ILCalendarEventRepository) {
        self.calendarEventRepository = calendarEventRepository
    }

    func loadDetail(code: String, date: Date, today: Date) async throws -> ILFestivalDetailEntity {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: day)

        let calendarEvents = try await calendarEventRepository.loadEvents(year: year)
        guard let event = calendarEvents.events.first(where: { $0.code == code }),
              let occurrence = calendarEvents.occurrences.first(where: {
                  $0.eventCode == code && calendar.isDate($0.solarDate, inSameDayAs: day)
              }) else {
            throw ILCatalogError.notFound
        }

        let groupNamesByCode = Dictionary(calendarEvents.groups.map { ($0.code, $0.name) }) { first, _ in first }
        let startOfToday = calendar.startOfDay(for: today)
        let daysUntil = calendar.dateComponents([.day], from: startOfToday, to: day).day ?? 0

        return ILFestivalDetailEntity(
            code: event.code,
            name: event.name,
            shortDescription: event.shortDescription,
            longDescription: event.longDescription,
            guidance: event.guidance,
            imageURL: event.imageURL,
            groupNames: event.groupCodes.compactMap { groupNamesByCode[$0] },
            date: day,
            lunarDay: occurrence.lunarDay,
            lunarMonth: occurrence.lunarMonth,
            isLeapMonth: occurrence.isLeapMonth,
            daysUntil: daysUntil
        )
    }
}
