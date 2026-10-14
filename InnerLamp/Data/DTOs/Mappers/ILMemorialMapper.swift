//
//  ILMemorialMapper.swift
//  InnerLamp
//

import Foundation

/// `ILMemorialEntity` <-> memorial DTOs.
///
/// The entity stores the date the way the form edits it (`day` / `month` in `calendarKind`, plus an
/// optional `deathYear` that is a *lunar* year for a lunar entry). The server wants a solar
/// `death_date` when the year is known, so this mapper converts in both directions.
nonisolated enum ILMemorialMapper {

    /// The entity cannot be expressed as a real calendar date (e.g. 31 April, or 29 February in a
    /// non-leap year).
    struct InvalidDateError: Error, Equatable {}

    // MARK: - Entity -> request

    static func toRequest(_ entry: ILMemorialEntity) throws -> ILMemorialRequestDTO {
        let reminder = entry.reminder.map {
            ILMemorialReminderRequestDTO(daysBefore: $0.leadDays, time: String(format: "%02d:%02d", $0.hour, $0.minute))
        }
        let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let year = entry.deathYear {
            let solar = try solarDate(of: entry, year: year)
            return ILMemorialRequestDTO(
                fullName: entry.name,
                relationship: relationshipWire(entry.relationship),
                deathCalendar: entry.calendarKind.rawValue,
                deathDate: String(format: "%04d-%02d-%02d", solar.year, solar.month, solar.day),
                deathDay: nil,
                deathMonth: nil,
                deathLeapMonth: nil,
                note: note,
                reminder: reminder,
                addToOsReminder: reminder != nil && entry.syncToReminders
            )
        }
        return ILMemorialRequestDTO(
            fullName: entry.name,
            relationship: relationshipWire(entry.relationship),
            deathCalendar: entry.calendarKind.rawValue,
            deathDate: nil,
            deathDay: entry.day,
            deathMonth: entry.month,
            // EN: Drift: product BR-MEM-04 keeps the leap marker — Docs/Specs/Memorial/tasks.md Phase 6.
            // VI: Lệch: product BR-MEM-04 giữ cờ tháng nhuận — Docs/Specs/Memorial/tasks.md Phase 6.
            deathLeapMonth: false,
            note: note,
            reminder: reminder,
            addToOsReminder: reminder != nil && entry.syncToReminders
        )
    }

    private static func solarDate(of entry: ILMemorialEntity, year: Int) throws -> ILLunarCalendar.SolarDate {
        switch entry.calendarKind {
        case .lunar:
            guard let solar = ILLunarCalendar.lunarToSolar(day: entry.day, month: entry.month, year: year) else {
                throw InvalidDateError()
            }
            return solar
        case .solar:
            let calendar = Calendar(identifier: .gregorian)
            let components = DateComponents(year: year, month: entry.month, day: entry.day)
            guard let date = calendar.date(from: components),
                  calendar.dateComponents([.year, .month, .day], from: date) == components else {
                throw InvalidDateError()
            }
            return ILLunarCalendar.SolarDate(day: entry.day, month: entry.month, year: year)
        }
    }

    // MARK: - DTO -> entity

    static func toDomain(_ dto: ILMemorialDTO) -> ILMemorialEntity {
        let kind = ILMemorialCalendarKind(rawValue: dto.deathCalendar) ?? .solar
        var day = dto.deathDay ?? 1
        var month = dto.deathMonth ?? 1
        var deathYear: Int?

        if let parts = solarParts(of: dto.deathDate) {
            switch kind {
            case .solar:
                (day, month, deathYear) = (parts.day, parts.month, parts.year)
            case .lunar:
                let lunar = ILLunarCalendar.solarToLunar(day: parts.day, month: parts.month, year: parts.year)
                (day, month, deathYear) = (lunar.day, lunar.month, lunar.year)
            }
        }

        return ILMemorialEntity(
            id: String(dto.id),
            name: dto.fullName,
            relationship: relationship(fromWire: dto.relationship),
            calendarKind: kind,
            day: day,
            month: month,
            deathYear: deathYear,
            note: dto.note ?? "",
            reminder: dto.reminder.flatMap(reminder(from:)),
            syncToReminders: dto.addToOsReminder,
            portraitFileName: nil
        )
    }

    private static func solarParts(of string: String?) -> (year: Int, month: Int, day: Int)? {
        guard let string else { return nil }
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return (parts[0], parts[1], parts[2])
    }

    private static func reminder(from dto: ILMemorialReminderDTO) -> ILMemorialReminder? {
        let parts = dto.time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return ILMemorialReminder(leadDays: dto.daysBefore, hour: parts[0], minute: parts[1])
    }

    // MARK: - Relationship

    private static func relationshipWire(_ relationship: ILMemorialRelationship) -> String {
        switch relationship {
        case .paternalGrandfather: return "GRANDFATHER_PATERNAL"
        case .maternalGrandfather: return "GRANDFATHER_MATERNAL"
        case .paternalGrandmother: return "GRANDMOTHER_PATERNAL"
        case .maternalGrandmother: return "GRANDMOTHER_MATERNAL"
        case .father: return "FATHER"
        case .mother: return "MOTHER"
        case .spouse: return "SPOUSE"
        case .sibling: return "SIBLING"
        case .child: return "CHILD"
        case .other: return "OTHER"
        }
    }

    private static func relationship(fromWire wire: String) -> ILMemorialRelationship {
        ILMemorialRelationship.allCases.first { relationshipWire($0) == wire } ?? .other
    }
}
