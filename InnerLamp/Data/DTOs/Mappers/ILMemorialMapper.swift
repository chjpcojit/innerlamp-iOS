//
//  ILMemorialMapper.swift
//  InnerLamp
//

import Foundation

/// `ILMemorialEntity` <-> memorial DTOs.
///
/// The entity stores the date the way the form edits it (`day` / `month` in `calendarKind`, an
/// optional `deathYear` that is a *lunar* year for a lunar entry, and the lunar leap flag). The
/// server wants a solar `death_date` when the year is known, so this mapper converts in both
/// directions (contract §2.3, D6).
nonisolated enum ILMemorialMapper {

    /// The entity cannot be expressed as a real calendar date (e.g. 31 April, or a leap month the
    /// lunar year does not have).
    struct InvalidDateError: Error, Equatable {}

    /// The server sent a value this client cannot represent. Surfaced as a controlled error rather
    /// than guessed (contract §2.2: never fall back to `OTHER`).
    struct UndecodableError: Error, Equatable {
        let field: String
    }

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
                reminder: reminder
            )
        }
        return ILMemorialRequestDTO(
            fullName: entry.name,
            relationship: relationshipWire(entry.relationship),
            deathCalendar: entry.calendarKind.rawValue,
            deathDate: nil,
            deathDay: entry.day,
            deathMonth: entry.month,
            // Only a lunar date can be in a leap month; the server rejects the flag for solar.
            deathLeapMonth: entry.calendarKind == .lunar ? entry.deathLeapMonth : nil,
            note: note,
            reminder: reminder
        )
    }

    private static func solarDate(of entry: ILMemorialEntity, year: Int) throws -> ILLunarCalendar.SolarDate {
        guard (1...12).contains(entry.month), (1...31).contains(entry.day) else {
            throw InvalidDateError()
        }
        switch entry.calendarKind {
        case .lunar:
            // A lunar year can have no leap month: `lunarToSolar` returns nil and the form must
            // block the save instead of storing a wrong solar date (contract §2.3, BR-MEM-04).
            guard let solar = ILLunarCalendar.lunarToSolarExact(
                day: entry.day,
                month: entry.month,
                year: year,
                isLeap: entry.deathLeapMonth
            ) else {
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

    static func toDomain(_ dto: ILMemorialDTO) throws -> ILMemorialEntity {
        guard let kind = ILMemorialCalendarKind(rawValue: dto.deathCalendar) else {
            throw UndecodableError(field: "death_calendar")
        }
        let relationship = try relationship(fromWire: dto.relationship)

        var day: Int
        var month: Int
        var deathYear: Int?
        var isLeapMonth = false

        if let deathDate = dto.deathDate {
            // EN: A present but unparseable/impossible `death_date` must fail the row. Falling back
            // to 1/1 would silently store a wrong death anniversary.
            // VI: `death_date` có nhưng hỏng/không tồn tại phải làm fail dòng đó. Fallback 1/1 sẽ
            // âm thầm lưu sai ngày giỗ.
            let parts = try parseSolarDate(deathDate)
            switch kind {
            case .solar:
                (day, month, deathYear) = (parts.day, parts.month, parts.year)
            case .lunar:
                let lunar = ILLunarCalendar.solarToLunar(day: parts.day, month: parts.month, year: parts.year)
                (day, month, deathYear) = (lunar.day, lunar.month, lunar.year)
                // The response has no leap flag for a known year; recover it from the solar date
                // (product Appendix B.1).
                isLeapMonth = lunar.isLeapMonth
            }
        } else {
            (day, month) = try yearlessParts(of: dto, kind: kind)
            isLeapMonth = kind == .lunar ? (dto.deathLeapMonth ?? false) : false
        }

        return ILMemorialEntity(
            id: String(dto.id),
            name: dto.fullName,
            relationship: relationship,
            calendarKind: kind,
            day: day,
            month: month,
            deathYear: deathYear,
            deathLeapMonth: isLeapMonth,
            note: dto.note ?? "",
            reminder: dto.reminder.flatMap(reminder(from:)),
            photoURL: dto.photoUrl.flatMap(URL.init(string:))
        )
    }

    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    /// Strict `YYYY-MM-DD`; both shape and calendar validity (31/2, 29/2 in a common year).
    private static func parseSolarDate(_ string: String) throws -> (year: Int, month: Int, day: Int) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            throw UndecodableError(field: "death_date")
        }

        let components = DateComponents(year: year, month: month, day: day)
        guard let date = gregorian.date(from: components),
              gregorian.dateComponents([.year, .month, .day], from: date) == components else {
            throw UndecodableError(field: "death_date")
        }
        return (year, month, day)
    }

    /// The no-year form (`death_day` + `death_month`). Both are required; there is no 1/1 default.
    private static func yearlessParts(
        of dto: ILMemorialDTO,
        kind: ILMemorialCalendarKind
    ) throws -> (day: Int, month: Int) {
        guard let month = dto.deathMonth else {
            throw UndecodableError(field: "death_month")
        }
        guard (1...12).contains(month) else {
            throw UndecodableError(field: "death_month")
        }
        guard let day = dto.deathDay else {
            throw UndecodableError(field: "death_day")
        }

        switch kind {
        case .solar:
            // The year is unknown, so February may be 29 (the server accepts it); 31/2 and 31/4
            // are still impossible. Validate against a leap year to allow 29/2.
            let components = DateComponents(year: 2024, month: month, day: day)
            guard let date = gregorian.date(from: components),
                  gregorian.dateComponents([.year, .month, .day], from: date) == components else {
                throw UndecodableError(field: "death_day")
            }
        case .lunar:
            guard (1...30).contains(day) else {
                throw UndecodableError(field: "death_day")
            }
        }
        return (day, month)
    }

    private static func reminder(from dto: ILMemorialReminderDTO) -> ILMemorialReminder? {
        let parts = dto.time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2,
              (0...23).contains(parts[0]),
              (0...59).contains(parts[1]) else { return nil }
        return ILMemorialReminder(leadDays: dto.daysBefore, hour: parts[0], minute: parts[1])
    }

    // MARK: - Relationship

    /// Explicit two-way table — never derived from the display string (contract §2.2).
    private static func relationshipWire(_ relationship: ILMemorialRelationship) -> String {
        switch relationship {
        case .paternalGrandfather: return "GRANDFATHER_PATERNAL"
        case .paternalGrandmother: return "GRANDMOTHER_PATERNAL"
        case .maternalGrandfather: return "GRANDFATHER_MATERNAL"
        case .maternalGrandmother: return "GRANDMOTHER_MATERNAL"
        case .father: return "FATHER"
        case .mother: return "MOTHER"
        case .spouse: return "SPOUSE"
        case .sibling: return "SIBLING"
        case .child: return "CHILD"
        case .other: return "OTHER"
        }
    }

    private static func relationship(fromWire wire: String) throws -> ILMemorialRelationship {
        switch wire {
        case "GRANDFATHER_PATERNAL": return .paternalGrandfather
        case "GRANDMOTHER_PATERNAL": return .paternalGrandmother
        case "GRANDFATHER_MATERNAL": return .maternalGrandfather
        case "GRANDMOTHER_MATERNAL": return .maternalGrandmother
        case "FATHER": return .father
        case "MOTHER": return .mother
        case "SPOUSE": return .spouse
        case "SIBLING": return .sibling
        case "CHILD": return .child
        case "OTHER": return .other
        default: throw UndecodableError(field: "relationship")
        }
    }
}
