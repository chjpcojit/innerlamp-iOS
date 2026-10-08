# Assumptions — LunarCalendar

Version: 1.0
Last updated: 2026-09-30

## A1 — Day 30 in a 29-day month falls on day 29
- Rationale: matches the existing `ILDeityUseCase` behavior and the catalog note
  "Tháng thiếu tính ngày 29"; otherwise Địa Tạng (30/7) and 30/9 events vanish in
  short months.
- Implication: applies to fast days, Buddhist events and deity memorial days.
- Validation: ⚠️ Not confirmed by product/tradition reviewer. Tests scan real
  calendars (2021-2030), not hardcoded dates.

## A2 — Leap months do not repeat recurring events
- Rationale: existing iOS behavior (`isLeapMonthEligible`, Festivals, Deity).
  New moon / full moon remain fast days in a leap month.
- Validation: ⚠️ Not confirmed; all seed templates have `isLeapMonthEligible = false`.

## A3 — Android follows the same rules
- Android `GetBuddhistEventMonthsUseCase` currently fires events in leap months
  and drops day 30 in short months; to be aligned with A1/A2.
