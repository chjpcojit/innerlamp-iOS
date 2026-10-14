//
//  ILCalendarEventMapper.swift
//  InnerLamp
//

import Foundation

/// Converts the calendar-events DTO into Domain entities.
nonisolated enum ILCalendarEventMapper {

    /// An occurrence whose `solar_date` cannot be parsed, or whose `event_code` has no entry in
    /// `events`, is dropped — it could not be shown anyway.
    static func toDomain(_ dto: ILCalendarEventsDTO, calendar: Calendar = Calendar(identifier: .gregorian)) -> ILCalendarEventsEntity {
        let events = dto.events.map { event in
            ILCalendarEventEntity(
                code: event.code,
                name: event.name.trimmingCharacters(in: .whitespacesAndNewlines),
                shortDescription: event.shortDescription,
                longDescription: event.longDescription,
                guidance: event.guidance,
                imageURL: event.imageUrl.flatMap(nonEmpty),
                groupCodes: event.groups,
                isPublicHoliday: event.isPublicHoliday
            )
        }
        let knownCodes = Set(events.map(\.code))
        let occurrences = dto.occurrences.compactMap { occurrence -> ILCalendarOccurrenceEntity? in
            guard knownCodes.contains(occurrence.eventCode),
                  let date = date(fromSolarString: occurrence.solarDate, calendar: calendar)
            else { return nil }
            return ILCalendarOccurrenceEntity(
                eventCode: occurrence.eventCode,
                solarDate: date,
                lunarDay: occurrence.lunarDate.day,
                lunarMonth: occurrence.lunarDate.month,
                isLeapMonth: occurrence.lunarDate.isLeapMonth
            )
        }
        return ILCalendarEventsEntity(
            year: dto.year,
            groups: dto.groups.map { ILCalendarGroupEntity(code: $0.code, name: $0.name) },
            events: events,
            occurrences: occurrences
        )
    }

    /// `yyyy-MM-dd` → start of that day in `calendar` (device time zone), so the day-of-month the
    /// user sees is exactly the server's `solar_date`.
    static func date(fromSolarString text: String, calendar: Calendar) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
