//
//  ILBuddhistEventUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILBuddhistEventUseCase {

    /// Loads the recurring Buddhist event templates from the store (seeding on first use).
    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity]

    /// Converts a solar date range into concrete Buddhist event occurrences.
    ///
    /// Each day in `[start, end)` is mapped to its lunar date via `ILLunarCalendar.solarToLunar`
    /// and matched against every template whose `lunarDay`/`lunarMonth` coincide. A template only
    /// matches a leap month when `isLeapMonthEligible` is `true` (the Vietnamese holidays in the
    /// seed catalog never are). Returns occurrences sorted chronologically.
    ///
    /// Pure and deterministic: given the same templates, range and calendar the result never changes.
    func occurrences(
        of templates: [ILBuddhistEventTemplateEntity],
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [ILBuddhistEventOccurrenceEntity]
}

final class ILBuddhistEventUseCaseImpl: ILBuddhistEventUseCase {

    private let repository: ILBuddhistEventRepository

    init(repository: ILBuddhistEventRepository) {
        self.repository = repository
    }

    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity] {
        try await repository.loadTemplates()
    }

    func occurrences(
        of templates: [ILBuddhistEventTemplateEntity],
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [ILBuddhistEventOccurrenceEntity] {
        guard !templates.isEmpty else { return [] }

        var result: [ILBuddhistEventOccurrenceEntity] = []
        var day = calendar.startOfDay(for: start)
        let lastDay = calendar.startOfDay(for: end)

        while day < lastDay {
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            for template in templates where template.lunarMonth == lunar.month && template.lunarDay == lunar.day {
                // A leap month is a distinct occurrence; only eligible templates fire there.
                if lunar.isLeapMonth && !template.isLeapMonthEligible { continue }
                result.append(ILBuddhistEventOccurrenceEntity(date: day, template: template))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        return result.sorted { $0.date < $1.date }
    }
}
